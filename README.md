# redmine-backup_task_plugin

Rake task for [redmine](http://www.redmine.org/) data backup and restore.


## Setup

Copy this repository into `plugins` directory.

If you can use git:

```
$ cd path/to/redmine
$ git clone https://github.com/yasuoza/redmine-backup_task_plugin.git plugins/redmine-backup_task_plugin
```

Otherwise, download zip from `Download Zip` button on GitHub. Maybe you can see the button on the right side.

## Create a backup

This plugin backups `files` directory and db dump.

```
$ RAILS_ENV=production rake redmine:backup:create
```

You can use `REDMINE_BACKUP_DIR` environment variable to customize backup tar file directory.

```
$ RAILS_ENV=production REDMINE_BACKUP_DIR=~/backup rake redmine:backup:create
```

And for advanced usage, if you want to keep newly backups, you can use `REDMINE_BACKUP_KEEP_TIME`(sec) environment variable.

```
$ RAILS_ENV=production REDMINE_BACKUP_KEEP_TIME=86400 rake redmine:backup:create
```

## Restore from a backup

Restore is a reverse of backup. Import db dump and copy `files` directory.

```
$ RAILS_ENV=production rake redmine:backup:create
```

Of course, you can choose custom backup directory and specified backup file.

```
$ RAILS_ENV=production REDMINE_BACKUP_DIR=~/backup BACKUP=1395303655 rake redmine:backup:restore
```

## LICENSE

[GNU General Public License v2](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
