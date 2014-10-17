#!/usr/bin/env python

from __future__ import print_function

import argparse
import os
import sys


def parse_args():
    parser = argparse.ArgumentParser(description='Applications management utility.')
    subparsers = parser.add_subparsers(title='Available commands', dest='action', metavar='')

    create_parser = subparsers.add_parser('create', help='Create new application')
    create_parser.add_argument('name', help='application name')

    destroy_parser = subparsers.add_parser('destroy', help='Destroy one of the existing applications')
    destroy_parser.add_argument('name', help='application name')

    enable_parser = subparsers.add_parser('enable', help='Mark application as active and start')
    enable_parser.add_argument('name', help='application name')

    disable_parser = subparsers.add_parser('disable', help='Stop application and remove from active applications')
    disable_parser.add_argument('name', help='application name')

    return parser.parse_args()


def print_error(message):
    print('ERROR:', message, file=sys.stderr)


class Application:
    root = '/web/apps'

    @classmethod
    def create(cls, args):
        if cls.exists(args.name):
            print_error('Application already exists.')
            return

        app_path = cls.path(args.name)
        os.system('mkdir -p {0}/repo && cd {0}/repo && git init --bare > /dev/null'.format(app_path))
        os.system(
            'mkdir -p {0}/app && cd {0}/app && git init > /dev/null && '
            'git remote add origin ../repo > /dev/null'.format(app_path)
        )

    @classmethod
    def destroy(cls, args):
        if not cls.exists(args.name):
            print_error('Invalid application name.')
            return

        cls.disable(args)

        app_path = cls.path(args.name)
        os.system('rm -rf {0}'.format(app_path))

    @classmethod
    def enable(cls, args):
        if not cls.exists(args.name):
            print_error('Invalid application name.')
            return

    @classmethod
    def disable(cls, args):
        if not cls.exists(args.name):
            print_error('Invalid application name.')
            return

    @classmethod
    def exists(cls, name):
        return os.path.isfile(cls.path(name))

    @classmethod
    def path(cls, name):
        return os.path.join(cls.root, name)


if __name__ == '__main__':
    args = parse_args()
    getattr(Application, args.action)(args)

# echo "Application successfully created. Next steps:"
# echo "  1. Edit $app/fig.yml to configure server setup."
# echo "  2. Add config for ngingx."
# echo "  3. Push code into repository."
