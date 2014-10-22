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
    create_parser.add_argument('host', help='application host')

    destroy_parser = subparsers.add_parser('destroy', help='Destroy one of the existing applications')
    destroy_parser.add_argument('name', help='application name')

    enable_parser = subparsers.add_parser('enable', help='Mark application as active and start')
    enable_parser.add_argument('name', help='application name')

    disable_parser = subparsers.add_parser('disable', help='Stop application and remove from active applications')
    disable_parser.add_argument('name', help='application name')

    return parser.parse_args()


def print_error(message):
    print('ERROR:', message, file=sys.stderr)


class Port:
    file = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'run/port')

    @classmethod
    def get_and_increment(cls):
        with open(cls.file, 'r+') as f:
            port = int(f.read())
            f.seek(0)
            f.write(str(port + 1))
            f.truncate()
        return 8000 + port


class Application:
    apps_root = '/web/apps'
    utils_root = os.path.dirname(os.path.realpath(__file__))

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
        cls.update_hook(args.name, enable=False)

        data = {
            'name': args.name,
            'host': args.host,
            'port': Port.get_and_increment()
        }
        templates_directory = os.path.join(cls.utils_root, 'templates')
        for config in os.listdir(templates_directory):
            with open(os.path.join(templates_directory, config)) as f:
                template_string = f.read()
            with open(os.path.join(app_path, config), 'w') as f:
                f.write(template_string.format(**data))

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

        app_path = cls.path(args.name)

        os.system('cd {} && fig build'.format(app_path))
        cls.update_supervisor(args.name, enable=True)
        cls.update_hook(args.name, enable=True)
        cls.update_nginx(args.name, enable=True)

    @classmethod
    def disable(cls, args):
        if not cls.exists(args.name):
            print_error('Invalid application name.')
            return

        app_path = cls.path(args.name)

        cls.update_nginx(args.name, enable=False)
        cls.update_hook(args.name, enable=False)
        cls.update_supervisor(args.name, enable=False)
        os.system('cd {} && fig rm'.format(app_path))

    @classmethod
    def update_hook(cls, name, enable=True):
        app_path = cls.path(name)
        type_ = 'enabled' if enable else 'disabled'
        os.system('rm -f {0}/repo/hooks/post-update'.format(app_path))
        os.system('ln -s {0}/hooks/post-update-{1} {2}/repo/hooks/post-update'.format(cls.utils_root, type_, app_path))

    @classmethod
    def update_nginx(cls, name, enable=True):
        app_path = cls.path(name)
        os.system('rm -f /web/infrastructure/nginx/sites/{0}.conf'.format(name))
        if enable:
            os.system('cp {0}/nginx.conf /web/infrastructure/nginx/sites/{1}.conf'.format(app_path, name))
        os.system('supervisorctl restart nginx')

    @classmethod
    def update_supervisor(cls, name, enable=True):
        app_path = cls.path(name)
        os.system('rm -f /etc/supervisor/conf.d/{0}.conf'.format(name))
        if enable:
            os.system('ln -s {0}/supervisor.conf /etc/supervisor/conf.d/{1}.conf'.format(app_path, name))
        os.system('supervisorctl reread && supervisorctl update')

    @classmethod
    def exists(cls, name):
        return os.path.isdir(cls.path(name))

    @classmethod
    def path(cls, name):
        return os.path.join(cls.apps_root, name)


if __name__ == '__main__':
    args_ = parse_args()
    getattr(Application, args_.action)(args_)
