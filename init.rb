Redmine::Plugin.register :redmine_backup_supporter do
  name 'Redmine Backup Supporter plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  # Plugin settings
  settings default: {
    redmine_backup_dir: Rails.root.join('tmp').to_s,
    redmine_backup_keep_time: 0, # default: 0 (forever) (in seconds)
  }, partial: 'settings/backup_dir_settings'
end
