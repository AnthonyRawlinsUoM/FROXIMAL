import os
import csv
import io
import sys
import time
import untangle
import pandas as pd
import json
import yaml
import sqlite3
from pathlib import Path, PureWindowsPath
from glob import glob as glob
import csv
from io import StringIO
from sqlalchemy import create_engine
from tabulate import tabulate
import psycopg2
import re
from sqlalchemy.dialects.postgresql import insert
import Utility as utilities
import logging

logging.basicConfig(filename='froximal_out.log',
                    filemode='a',
                    format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
                    datefmt='%H:%M:%S',
                    level=logging.DEBUG)

logging.info("FROXIMAL")
# Don't modify these tables
not_required = [
    'version',
    'regimes',
    'sqlite_sequence',
    'replicates'
]


class SQLiteAdaptor:

    def __init__(self):
        self.name = 'SQLiteAdaptor'
        self.logger = logging.getLogger("SQLiteAdaptor")

    def copy_table(self, table, src, dest, regime, replicate, uuid):
        """
        For reading SQLite DBs and copying their content to outdb.
        This is where the magic happens by aggressively injecting 3 foreign
        keys into each row that are inserted into the index database that
        don't acually exist in the source databases.

        There's some juggling required to format an upsert handler.

        """
        start = time.time()

        # utilities.message("Copying %s %s => %s for %s, %s, %s" % (
        #     table, src, dest, regime, replicate, uuid)
        # )
        #
        sc = pd.read_sql_query('SELECT * FROM `%s`' % (table), src)

        # print(tabulate(sc, tablefmt='psql)'))

        triple_data = [[regime, replicate, uuid]] * \
            len(sc)  # As many rows as required
        triple = pd.DataFrame(triple_data, columns=[
                              'regime', 'replicate', 'uuid'])

        df = sc.join(triple)
        # print(tabulate(df, tablefmt='psql)'))

        # df.to_sql(table, engine)
        table = table.lower()
        # This overrides the dest!!!!!!!!!!!!!!!!

        engine = create_engine(
            'postgresql+psycopg2://postgres:secret@192.168.1.188:5432/WHOLE_TOMATOES')

        # Replaces contents of buffer not table in DB!
        df.head(0).to_sql(table, engine, if_exists='append',
                          index=False)  # truncates the table

        conn = engine.raw_connection()
        cur = conn.cursor()
        output = io.StringIO()
        df.to_csv(output, sep='\t', escapechar='\\',
                  quotechar="'", header=False, index=False)
        output.seek(0)
        contents = output.getvalue()
        cur.copy_from(output, table, null="")  # null values become ''
        conn.commit()
        conn.close()

        end = time.time()
        utilities.message("Ingested: %.5f seconds to copy Table (%s) for [%s], [%s]" % (
            (end - start), table, regime, replicate))

        #
        # print(tabulate(df.T, tablefmt='fancy_grid'))
        #
        # ins = None
        # dc = dest.cursor()
        # #
        # tuples = []
        # for row in sc.fetchall():
        #     # print(row)
        #
        #     row.append(regime)
        #     row.append(replicate)
        #     row.append(uuid)
        #
        #     tuples.append(row)
        #
        #     if not ins:
        #         orig_columns = []
        #         for k in row.keys():
        #             if k == 'left':
        #                 k = '_left'
        #             orig_columns.append(k)
        #         # print(orig_columns)
        #         columns = orig_columns
        #         columns.append('regime')
        #         columns.append('replicate')
        #         columns.append('uuid')
        #
        #         cols = tuple(columns)
        #         rows = "(%s)" % (','.join(['%s'] * len(cols)))
        #
        #         ins = "INSERT INTO %s (%s) VALUES (%s)" % (
        #             table, ', '.join(cols), )
        #         # print(ins)
        #
        #     # values_as_tuple = "%s" % (
        #     #     ', '.join("'{}'".format(k) for k in c))
        #     #
        #     # nonefix = values_as_tuple.replace("'None'", "NULL")
        #     # emptyfix = nonefix.replace("'',", "NULL,")
        #     #
        #     # tuples.append(emptyfix)
        #
        # utilities.message(ins)

        # dc.execute(ins, tuples)

        # dest.commit()

    def transfer_schema_to_destination(self,
                                       src,
                                       dest,
                                       triple={
                                           'regime': 1,
                                           'replicate': 'rep-1-1',
                                           'uuid': 'ce8add97-459d-4d27-8c06-4e31a74df13d'
                                       }
                                       ):
        start = time.time()

        sqls = self.modify_schema(src)

        dc = dest.cursor()
        # modified schema to destination
        [dc.execute(create) for create in sqls]
        dest.commit()
        dc.close()

        [self.copy_table(
            table[1],
            src,
            dest,
            triple['regime'],
            triple['replicate'],
            triple['uuid']
        ) for table in self.get_good_tables(src)]

        dest.close()
        src.close()
        end = time.time()
        utilities.message(
            'Transfer completed in %.5f seconds.' % (end - start))

    def get_good_tables(self, src):
        cur = src.cursor()
        cur.execute("SELECT * FROM sqlite_master where type='table'")
        tables = cur.fetchall()
        good_tables = []
        for tab in tables:
            table_name = tab[1]
            if table_name.lower() not in not_required:
                good_tables.append(tab)
        cur.close()
        return good_tables

    def modify_schema(self, src):
        """
            Given a cursor to the SQLite DB, return a list of all its CREATE
            statements and modify them to include regime, replicate
            and uuid columns.
        """
        sqls = []
        for tab in self.get_good_tables(src):
            # CREATE STATEMENT
            # This only replaces if it exists!
            create = tab[-1]
            create = create.replace('INTEGER PRIMARY KEY', 'BIGSERIAL')
            create = create.replace('integer PRIMARY KEY', 'BIGSERIAL')
            # modify the create statement
            if 'id BIGSERIAL' in create:
                mod = """,
                regime  	TEXT NOT NULL,
                replicate 	TEXT NOT NULL,
                uuid      	TEXT NOT NULL,

                FOREIGN KEY (uuid) REFERENCES job (uuid),
                PRIMARY KEY (id, uuid, replicate)
            )"""
            else:
                mod = """,
                regime  	TEXT NOT NULL,
                replicate 	TEXT NOT NULL,
                uuid      	TEXT NOT NULL,

                FOREIGN KEY (uuid) REFERENCES job (uuid)
            )"""

            m = re.search(r"\[(\w+)\]", create)
            if m is not None:
                create = create.replace(m.group(1), '')
            create = create.replace('CHECK (sim_finalised IN (0, 1))', '')

            """ Last instance of close bracket only! - VERIFY THIS!
             Thanks to StackOverflow here:
             https://stackoverflow.com/questions/2556108/rreplace-how-to-replace-the-last-occurrence-of-an-expression-in-a-string
            """
            create = create.replace(' left ', ' _left ').replace(
                'DATETIME', 'TIMESTAMP')
            modded = mod.join(create.rsplit(')', 1))

            only_once = 'CREATE TABLE IF NOT EXISTS '.join(
                modded.rsplit('CREATE TABLE ', 1))

            only_once = only_once.replace("'None'", "NULL")
            only_once = only_once.replace("'',", "NULL,")

            self.logger.info(only_once)

            sqls.append(only_once)

        return sqls

    def psql_insert_copy(table, conn, keys, data_iter):
        """
            For future dev...
            Apparently this function is much faster....
        """
        # gets a DBAPI connection that can provide a cursor
        dbapi_conn = conn.connection
        with dbapi_conn.cursor() as cur:
            s_buf = StringIO()
            writer = csv.writer(s_buf)
            writer.writerows(data_iter)
            s_buf.seek(0)

            columns = ', '.join('"{}"'.format(k) for k in keys)
            if table.schema:
                table_name = '{}.{}'.format(table.schema, table.name)
            else:
                table_name = table.name

            sql = 'COPY {} ({}) FROM STDIN WITH CSV'.format(
                table_name, columns)
            cur.copy_expert(sql=sql, file=s_buf)

# engine = create_engine('postgresql://myusername:mypassword@myhost:5432/mydatabase')
# df.to_sql('table_name', engine, method=psql_insert_copy)

    def test_myself(self):
        test_in = sqlite3.connect('adaptor.test.sqlite')
        test_in.row_factory = sqlite3.Row
        test_out = psycopg2.connect(
            'postgresql://postgres:secret@192.168.1.188:5432/Froximal')

        self.transfer_schema_to_destination(test_in, test_out)
