import pandas as pd
import os
import sys
import traceback
from tabulate import tabulate
from glob import glob as glob
import re
import psycopg2
# import only system from os
from os import system, name
from datetime import datetime
# import sleep to show output for some time period
from time import sleep
from pathlib import Path


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def warn(s):
    print(f'{bcolors.WARNING}[Warning]: ' + s)
    print(f'{bcolors.ENDC}')


def error(error_type):
    exc_info = sys.exc_info()
    print(
        f'{bcolors.FAIL}'
        + '[Error]: '
        + f'{bcolors.ENDC}'
        + str(error_type)
    )
    print(f'{bcolors.FAIL}[Error]:\n\n')
    traceback.print_exception(*exc_info)
    print(f'{bcolors.ENDC}\n\n\n')


def message(s):
    bprint(s)


def bprint(s):
    print(
        f'{bcolors.BOLD}'
        + '[FROXIMAL %s]: ' % (datetime.now())
        + f'{bcolors.ENDC}'
        + s
    )


class DisplayablePath(object):
    display_filename_prefix_middle = '├──'
    display_filename_prefix_last = '└──'
    display_parent_prefix_middle = '    '
    display_parent_prefix_last = '│   '

    def __init__(self, path, parent_path, is_last):
        self.path = Path(str(path))
        self.parent = parent_path
        self.is_last = is_last
        if self.parent:
            self.depth = self.parent.depth + 1
        else:
            self.depth = 0

    @property
    def displayname(self):
        """
        Sets console to display bold for *.proj files or appends / to dirs
        """
        if self.path.is_dir():
            if (is_uuid(self.path.parts[-1])):
                self.is_uuid_folder = True
            return self.path.name + '/'
        elif is_proj(self.path.parts[-1]):
            return f'{bcolors.BOLD}' + self.path.name + f'{bcolors.ENDC}'
        return self.path.name

    @classmethod
    def make_tree(cls, root, parent=None, is_last=False, criteria=None):
        root = Path(str(root))
        criteria = criteria or cls._default_criteria

        displayable_root = cls(root, parent, is_last)
        yield displayable_root

        children = sorted(list(path
                               for path in root.iterdir()
                               if criteria(path)),
                          key=lambda s: str(s).lower())
        count = 1
        for path in children:
            is_last = count == len(children)
            if path.is_dir():
                yield from cls.make_tree(path,
                                         parent=displayable_root,
                                         is_last=is_last,
                                         criteria=criteria)
            else:
                yield cls(path, displayable_root, is_last)
            count += 1

    @classmethod
    def _default_criteria(cls, path):
        return True

    def displayable(self):
        if self.parent is None:
            return self.displayname

        _filename_prefix = (self.display_filename_prefix_last
                            if self.is_last
                            else self.display_filename_prefix_middle)

        parts = ['{!s} {!s}'.format(_filename_prefix,
                                    self.displayname)]

        parent = self.parent
        while parent and parent.parent is not None:
            parts.append(self.display_parent_prefix_middle
                         if parent.is_last
                         else self.display_parent_prefix_last)
            parent = parent.parent

        return ''.join(reversed(parts))


def clear():

    # for windows
    if name == 'nt':
        _ = system('cls')
    # for mac and linux(here, os.name is 'posix')
    else:
        _ = system('clear')


def unicode_booleans(bool):
    if (bool):
        return u"\u2611"
    else:
        return u"\u2610"


def check_and_get_path_sanity(path):

    data = [[
        path,
        unicode_booleans(os.access(path, os.R_OK)),
        unicode_booleans(os.access(path, os.W_OK)),
        unicode_booleans(os.access(path, os.X_OK))
    ]]

    permissons_table = pd.DataFrame(
        data, columns=['Path', 'Read', 'Write', 'Execute'])
    permissons_table.set_index('Path')
    return tabulate(permissons_table, headers=['Path', 'R', 'W', 'X'])

# print(check_and_get_path_sanity('.'))


def permissons_truth_table_for_path_list(list_of_paths):
    return [[
        path,
        unicode_booleans(os.access(path, os.R_OK)),
        unicode_booleans(os.access(path, os.W_OK)),
        unicode_booleans(os.access(path, os.X_OK))
    ] for path in list_of_paths]


def tabulate_permissions(permissions_truth_table):
    # check shape of data
    permissons_table = pd.DataFrame(permissions_truth_table, columns=[
                                    'Path', 'Read', 'Write', 'Execute'])
    permissons_table.set_index('Path')
    return tabulate(permissons_table, headers=['Path', 'R', 'W', 'X'])

# print(tabulate_permissions(permissons_truth_table_for_path_list(glob('../*'))))


def check_path_sanity(list_of_paths):
    for p in list_of_paths:
        if not os.path.exists(p):
            print('Missing: %s' % (p))
            return False
    return True


def report_path_sanity(list_of_paths):
    """
    Checks paths if they exist AND/OR permissions.
    Failures should cascade so that if any file or folder does not match expectations, the sanity fails.
    """
    sanity_truth_table = [[
        path,
        unicode_booleans(os.path.exists(path)),
        unicode_booleans(os.path.isfile(path)),
        unicode_booleans(os.path.isdir(path))
    ] for path in list_of_paths]

    cols = ['Path', 'Exists', 'File', 'Folder']

    sanity_table = pd.DataFrame(sanity_truth_table, columns=cols)
    sanity_table.set_index('Path')
    return tabulate(sanity_table, headers=cols)

# print(check_path_sanity(glob('../*')))


""" Just a helper """


def is_uuid(path_is_uuid):
    return valid_uuid(str(path_is_uuid))


def valid_uuid(uuid):
    uuid4hex = re.compile(
        '[0-9a-f]{8}\-[0-9a-f]{4}\-4[0-9a-f]{3}\-[89ab][0-9a-f]{3}\-[0-9a-f]{12}', re.I)
    match = uuid4hex.match(uuid)
    return bool(match)


def insert(sql):
    last_id = None

    try:
        # read database configuration
        # connect to the PostgreSQL database

        print('Connecting to DB')
        conn = psycopg2.connect(bucket)

        # create a new cursor
        cur = conn.cursor()

        # execute the INSERT statement

#         print(sql)

        cur.execute(sql)
        row = cur.fetchone()
        last_id = row[0]

        while row is not None:
            #             print(row)
            row = cur.fetchone()

        conn.commit()

        # close communication with the database
        cur.close()

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            print('Closing connection to DB')
            conn.close()
    return last_id


def truthiness(string):
    if type(string) == str:
        return (string.upper() == 'TRUE')
    else:
        return string


# def find_or_insert(db, table, value):
#
#     sql = """
#     SELECT
#         %s
#     FROM
#         public.%s
#     WHERE
#         %s like '%%%s%%'
#     ORDER BY %s
#     LIMIT 1;
#     """ % (
#         table + '_id',
#         table,
#         table + '_name',
#         value.lower(),
#         table + '_id'
#     )
#
#     _id = None
#
#     try:
#         # connect to the PostgreSQL database
#         conn = psycopg2.connect(db)
#         # create a new cursor
#         cur = conn.cursor()
#         # execute the SELECT statement
#         cur.execute(sql)
#
#         # get the id back
#         row = cur.fetchone()
#         _id = row[0]
#
#         while row is not None:
#             #             print(row)
#             row = cur.fetchone()
#
#         conn.commit()
#
#         # close communication with the database
#         cur.close()
#
#     except (Exception, psycopg2.DatabaseError) as error:
#         print(error)
#     finally:
#         if conn is not None:
#             conn.close()
#
#     if (_id is None):
#         print('Not found. Creating.')
#         sql = """
#         INSERT INTO
#             public.%s (
#                 %s
#             )
#         VALUES (
#             '%s'
#         )
#         RETURNING %s.%s;
#         """ % (
#             table,
#             table + '_name',
#             value,
#             table,
#             table + '_id',
#         )
#         return insert(sql)
#     else:
#         print(table + '_id: %s' % _id)
#         return _id


def crit(p):
    """ Answers search criteria with a boolean """
    return any([
        is_proj(p),
        is_uuid(p),
        is_sqlite(p),
        contains_uuid_folder(p),
        contains_proj_file(p),
        contains_sqlite(p)
    ])


def contains_uuid_folder(path):
    return any(
        [any(
            [is_uuid(u) for u in f.split('/')])
         for f in glob(str(path)
                       + '/**')
         ]
    )


def extract_uuid_from_path(path):
    for p in path.parts:
        if is_uuid(p):
            return p
    raise Exception('No UUID found for given path.')


def is_proj(path):
    # return any([('.proj' in p) for p in path.parts])
    return (str(path)[-5:] == '.proj')


def is_sqlite(path):
    return (str(path)[-7:] == '.sqlite')


def contains_sqlite(path):
    return any([is_sqlite(p) for p in [a for a in glob(str(path) + '/**')]])


def contains_proj_file(path):
    return any([is_proj(p) for p in [a for a in glob(str(path) + '/**')]])
