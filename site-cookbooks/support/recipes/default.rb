# support tools
remote_file "/usr/local/bin/support_check.rb" do
  source "support_check.rb"
  mode 0755
end

cron "support email queue check" do
  command "/usr/local/bin/support_check.rb"
end