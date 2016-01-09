
require 'carrierwave'
require 'carrierwave/validations/active_model'


class NullStorage
  attr_reader :uploader

  def initialize(uploader)
    @uploader = uploader
  end

  def identifier
    uploader.filename
  end

  def store!(_file)
    true
  end

  def retrieve!(_identifier)
    true
  end
end

CarrierWave.configure do |config|
  if Rails.env.test?
    # http://stackoverflow.com/questions/7534341/rails-3-test-fixtures-with-carrierwave/25315883#25315883
    config.storage NullStorage
  else
    config.storage = :qiniu
  end

  config.qiniu_access_key    = Setting.qiniu_access_key
  config.qiniu_secret_key    = Setting.qiniu_secret_key
  config.qiniu_bucket        = Setting.qiniu_bucket
  config.qiniu_bucket_domain = Setting.qiniu_bucket_domain
  config.qiniu_bucket_private= Setting.qiniu_bucket_private
  config.qiniu_block_size    = Setting.qiniu_block_size
  config.qiniu_protocol      = Setting.qiniu_protocol
end
