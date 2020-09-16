
import os
import sys
import untangle
import pandas as pd
import json
import yaml
import sqlite3
from pathlib import Path, PureWindowsPath
from glob import glob as glob
from sqlalchemy import create_engine
from tabulate import tabulate
import psycopg2
import re
import math

import Utility as utilities
from SQLiteAdaptor import SQLiteAdaptor


class WebFrostJobIngestor:

    def __init__(self, data_storage, indb, outdb):

        # Not required?
        self.ingest_path = data_storage + '/frappeator_out'
        self.glaciator_path = data_storage + '/glaciator_out'

        try:
            self.file_integrity_test()
        except Exception as e:
            utilities.message('Failed integrity checking.')
            raise RuntimeError from e

        # - TODO create if not exists??

        self.indb = indb
        self.outdb = outdb

        utilities.message('WebFrostJobIngestor has initialised.')

    def good_connections(self):
        try:
            with create_engine(self.indb).connect() as _conn:
                utilities.message(
                    'Connected to Input Postgres Server @ DeepBlack.cloud')

            with create_engine(self.outdb).connect() as _conn:
                utilities.message(
                    'Connected to Output Postgres Server @ DeepBlack.cloud')

        except Exception as e:
            raise ConnectionError from e
        return True

    def faulted(self):
        jobs = self.jobs()
        return list(jobs['uuid'].where(
            pd.notnull(jobs['job_failure_time'])).dropna())

    def prepared(self):
        jobs = self.jobs()
        return list(jobs['uuid'].where(
            pd.notnull(jobs['job_completion_time'])).dropna())

    def unpublished(self):
        jobs = self.jobs()
        return list(jobs['uuid'].where(jobs['published'] == False).dropna())

    def glaciator_uuids(self):
        uuid_paths = glob(self.glaciator_path
                          + '/glaciator_project_file/*.glaciator.proj',
                          recursive=True)
        uuids = [p.split('/')[-1].replace('.glaciator.proj', '')
                 for p in uuid_paths]

        return [uuid for uuid in uuids if utilities.valid_uuid(uuid)]

    def frappeator_uuids(self):
        uuids = [p.split('/')[-3]
                 for p in glob(self.ingest_path
                               + '/**/*.frappeator.proj',
                               recursive=True)]

        return [uuid for uuid in uuids if utilities.valid_uuid(uuid)]

    def projects(self):
        projects = glob(self.ingest_path + '/**/*.proj', recursive=True)
        return projects

    def glaciators(self):
        return glob(self.glaciator_path
                    + 'glaciator_project_file/*.glaciator.proj', recursive=True)

    def cross_match(self):

        g = self.glaciator_uuids()
        f = self.frappeator_uuids()

        have_data = [h for h in f if h in g]
        print('Data for: %s' % len(have_data))
        p = self.prepared()
        print('Post-processed: %s' % len(p))
        x = self.faulted()
        print('Faulted: %s' % len(x))
        u = self.unpublished()
        print('Unpublished: %s' % len(u))

        db_ready = [d for d in p if d not in x and d in u]

        print('Good to go: %s' % len(db_ready))

        return [g2g for g2g in have_data if g2g in db_ready]

    def file_integrity_test(self):
        for p in [self.glaciator_path, self.ingest_path]:
            if not os.path.exists(p):
                utilities.warn('Warning: Could not find: ' + p + '!')
                return False
            else:
                utilities.message('Validated the existence of: ' + p)
        return True

    def projects_ready(self):
        # Compare completed uuids to whats in frappeator_out
        g2g = []

        for p in self.projects():
            # print('Checking Project: %s' % p)
            for c in self.prepared():
                # print('Checking if %s is in %s' % (c, p))
                if c in p:
                    #             print(p)
                    g2g.append(p)

        # We must also scan glaciator_out for matching uuids before ImportWarning
        # SEE: cross_match()
        return g2g

    def jobs(self):

        jobs = []

        with create_engine(self.indb).connect() as _conn:
            # print('Connected to Postgres Server @ DeepBlack')
            jobs = pd.read_sql_query("""

            SELECT
                job.uuid,
                job.name,
                jobstate.job_completion_time,
                jobstate.job_failure_time,
                jobstate.published
            FROM
                job
            INNER JOIN
                jobtojobstate
            ON
                job.id=jobtojobstate.job_id
            INNER JOIN
                jobstate
            ON
                jobtojobstate.job_state_id = jobstate.id
            WHERE
                published = false
            ORDER BY
                submission_time,
                submitter_name

            """, _conn)
        return jobs

    def open_db(self, nam):
        """
        Creates connections with Tuple / Row factory records by default
        """
        conn = sqlite3.connect(nam)
        # Let rows returned be of dict/tuple type
        conn.row_factory = sqlite3.Row
        print("Opened database %s as %s" % (nam, conn))
        return conn

    # def parse_ready_projects(self):
    #     return [proj for proj in self.cross_match()]

    def report(self):
        print('=== Start of Report ===')
        [print(fproj) for fproj in self.cross_match()]
        print('=== End of Report ===')

    def set_published_flag(self, uuid):
        try:
            with create_engine(self.indb).connect() as _conn:
                _conn.execute("""
    UPDATE
        jobstate
    SET published = true
    WHERE
        jobstate.id = (
            SELECT
                jobstate.id
            FROM
                job
            INNER JOIN
                jobtojobstate
            ON
                job.id=jobtojobstate.job_id
            INNER JOIN
                jobstate
            ON
                jobtojobstate.job_state_id = jobstate.id
            WHERE
                job.uuid = '%s'
    );
                """ % (
                    uuid
                ))
                # print("[We just published: %s]" % uuid)
        except (Exception, psycopg2.DatabaseError) as error:
            print(error)

    def ingest(self):
        """
            This is a stub only
        """
        imported_ids = []

        g2g_ids = self.cross_match()

        # BEGIN TRANSACTION
        for uuid in g2g_ids:
            try:
                utilities.message("Now importing: %s" % uuid)
                self.import_glaciator(uuid)

            except Exception as e:
                tb = sys.exc_info()[2]
                raise RuntimeError(
                    'Importing failed') from e.with_traceback(tb)
                sys.exit(0)

            imported_ids.append(uuid)
            self.set_published_flag(uuid)

        return imported_ids

    def import_sqlite(self, db_path, regime, replicate, uuid):
        sqla = SQLiteAdaptor()
        sqli = sqlite3.connect(db_path)
        sqli.row_factory = sqlite3.Row
        sqlo = psycopg2.connect(self.outdb)

        sqla.transfer_schema_to_destination(src=sqli,
                                            dest=sqlo,
                                            triple={
                                                'regime': regime,
                                                'replicate': replicate,
                                                'uuid': uuid
                                            })
        sqli.close()

    def import_project_info(self, gpi_path, regime, replicate, uuid):
        sqla = SQLiteAdaptor()
        sqli = sqlite3.connect(gpi_path)
        sqli.row_factory = sqlite3.Row
        sqlo = psycopg2.connect(self.outdb)

        sqla.transfer_schema_to_destination(src=sqli,
                                            dest=sqlo,
                                            triple={
                                                'regime': regime,
                                                'replicate': replicate,
                                                'uuid': uuid
                                            })
        sqli.close()

    def import_glaciator(self, uuid):

        gp = self.glaciator_path + '/glaciator_project_file/' + uuid + '.glaciator.proj'
        print(gp)

        x = untangle.parse(gp)
        version = x.glaciator_project['version']
        name = x.glaciator_project.glaciator_project_name.cdata
        regime = name

        utilities.message(
            "Ingesting %s (GlaciatorProject v%s)" % (name, version))
        # print(x.glaciator_project)
        self.import_sql(gp, mode='CREATE')
        self.import_sql(gp, mode='insert')


        for mp in x.glaciator_project.frost_auto_multi_project_regular:
            subproject_name_mask = mp.subproject_name_mask.cdata
            regsim_index_start = int(mp.regsim_index_start.cdata)
            regsim_index_end = int(mp.regsim_index_end.cdata)
            multi_project_name = mp.multi_project_name.cdata

            width = math.floor((regsim_index_end - regsim_index_start)/10)

            glaciator_replicate_paths = [subproject_name_mask.replace(
                '*', ('%d' % i).zfill(width)) for i in range(regsim_index_start, regsim_index_end)]

            for replicate in glaciator_replicate_paths:
                # Multiple frost_auto_multi_project_regular ???
                proj_path = self.glaciator_path + '/' + uuid + '/' + \
                    name + '/' + multi_project_name + '/' + replicate + '/'

                fproj_path = proj_path + replicate + '.frost.proj'

                gpi_proj_path = proj_path + 'project_info.sqlite'

                self.import_sql(fproj_path, mode='CREATE')
                self.import_sql(fproj_path, mode='insert')

                regime = name
                fire_impacts = glob(proj_path + '/fire_impacts_*.sqlite')
                self.import_sqlite(
                    proj_path + '/fire_impact_databases_index.sqlite', regime, replicate, uuid)
                [self.import_sqlite(fi, regime, replicate, uuid)
                 for fi in fire_impacts]

                self.import_project_info(
                    gpi_proj_path, regime, replicate, uuid)

                self.import_frappeator(
                    uuid, regime, replicate)

                sqls_path = self.ingest_path + '/' + uuid + '/' + \
                    name + '/' + name + '/' + multi_project_name + '/' + replicate + '/'

                utilities.message("Here we import the *.sqlite files...")
                sql_list = glob(sqls_path + 'post_processing_output/*.sqlite')
                utilities.message(',\n'.join(sql_list))

                [self.import_sqlite(db_path, regime, replicate, uuid)
                 for db_path in sql_list]

        # self.import_sqlites(uuid)
    def get_regime_for(self, uuid):
        return self.run_query_on_outdb("""SELECT frost_regsim_project_id FROM frost_regsim_projects WHERE uuid = '%s'""" % uuid)

    # def find_frappeator(self, uuid):
    #     return glob(self.ingest_path
    #                 + '/' + uuid + '/*.frappeator.proj', recursive=False)

    # def find_frost(self, uuid):
    #     return glob(self.glaciator_path
    #                 + '/' + uuid + '/**/*.frost.proj', recursive=True)

    def import_frappeator(self, uuid, regime, replicate):

        frappeator = self.ingest_path + '/' + uuid + \
            '/%s.frappeator.proj' % (regime)

        utilities.warn(frappeator)

        x = untangle.parse(frappeator)

        version = x.frappeator_project['version']
        name = x.frappeator_project.project_name.cdata

        # TODO - Verify existence using utilities!
        path = frappeator.replace('.frappeator.proj', '')
        uuid = None
        for candidate in path.split('/'):
            if(utilities.is_uuid(candidate)):
                uuid = candidate
        if uuid is None:
            utilities.error('Fatal Error: could not parse the uuid.')
            sys.exit(0)

        utilities.message(
            """Found a Frappeator v%s Project %s %s %s %s""" % (
                version,
                'called:' + f'{utilities.bcolors.BOLD}',
                name,
                f'{utilities.bcolors.ENDC}',
                uuid))

        is_frost_multi_proj = (
            x.frappeator_project.is_frost_multi_proj.cdata.upper() == 'TRUE'
        )
        regimes = []

        if is_frost_multi_proj:
            utilities.message('This Job has sub-projects (aka. Regimes)!')

        for multis in x.frappeator_project.frappe_multi_project:
            [regimes.append(m.cdata) for m in
             multis.frost_output_results_dir_rel_path]

        utilities.message("It contains %s sub-projects." % (len(regimes)))

        # Read in the .sql.xml files
        self.import_sql(frappeator, mode='CREATE')
        self.import_sql(frappeator, mode='insert')

        utilities.message('Successfully imported.')

        # print('Done.')
        # END TRANSACTION!

    def execute_statement_on_outdb(self, sql):
        try:
            # connect to the PostgreSQL database
            conn = psycopg2.connect(self.outdb)
            # create a new cursor
            cur = conn.cursor()
            # execute the SELECT statement
            cur.execute(sql)
            conn.commit()

            # close communication with the database
            cur.close()
        except (Exception, psycopg2.DatabaseError) as error:
            utilities.error('SQL Query failed: %s' % (sql))
            raise RuntimeError('SQL Query failed.') from error
        finally:
            if conn is not None:
                conn.close()

    def run_query_on_outdb(self, sql):
        _id = -1
        try:
            # connect to the PostgreSQL database
            conn = psycopg2.connect(self.outdb)
            # create a new cursor
            cur = conn.cursor()
            # execute the SELECT statement
            cur.execute(sql)
            conn.commit()
            # get the id back
            row = cur.fetchone()
            _id = row[0]

            while row is not None:
                # print(row)
                row = cur.fetchone()

            # close communication with the database
            cur.close()
        except (Exception, psycopg2.DatabaseError) as error:
            utilities.error('SQL Query failed: %s' % (sql))
            raise RuntimeError('SQL Query failed.') from error
        finally:
            if conn is not None:
                conn.close()
        return _id

    def import_sql(self, path, mode='insert'):
        sqlpath = Path(str(path).replace('.proj', '.sql.xml'))
        # check it exists again?
        if not os.path.exists(sqlpath):
            raise RuntimeError(
                '*.sql.xml not found! Did you SQLize the Data Store?\nExpected:\n%s' % sqlpath)

        utilities.message('Checking for %s: %s' % (mode, sqlpath))
        sql_root = untangle.parse(str(sqlpath))
        statements = sql_root.sqlgroup.sqlstatement
        if(mode == 'CREATE'):
            [self.execute_statement_on_outdb(sql.cdata)
             for sql in statements if sql['action'] == 'CREATE']

        if(mode == 'insert'):
            [self.run_query_on_outdb(sql.cdata)
             for sql in statements if sql['action'] == 'insert']

        # do import of sqlite sub-components
