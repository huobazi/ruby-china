require 'qiniu'
namespace :assets do
  desc 'sync assets to cdns'
  task cdn: :environment do
    Qiniu.establish_connection! :access_key => Setting.qiniu_access_key,
                                :secret_key => Setting.qiniu_secret_key

    put_policy = Qiniu::Auth::PutPolicy.new(
      Setting.qiniu_bucket     # 存储空间
    )
    uptoken = Qiniu::Auth.generate_uptoken(put_policy)
    Dir.glob("#{Rails.root}/public/assets/**/*").each do |asset|
      next if File.directory?(asset)
      asset =~ /public(\/assets.*$)/
      filename = $1
      key = filename
      code, result, response_headers = Qiniu::Storage.upload_with_put_policy(
        put_policy,     # 上传策略
        asset,          # 本地文件名
        key             # 最终资源名，可省略，缺省为上传策略 scope 字段中指定的Key值
      )
    end
  end
end
