# frozen_string_literal: true

class UserSettings
  class Error < StandardError; end
  class KeyError < Error; end

  include UserSettings::DSL
  include UserSettings::Glue

  setting :always_send_emails, default: false
  setting :aggregate_reblogs, default: true
  setting :flavour, default: -> { ::Setting.flavour }
  setting :skin, default: -> { ::Setting.skin }
  setting :noindex, default: -> { ::Setting.noindex }
  setting :show_application, default: true
  setting :default_language, default: nil
  setting :default_sensitive, default: false
  setting :default_privacy, default: nil, in: %w(public unlisted private)
  setting :default_content_type, default: 'text/plain'
  setting :hide_followers_count, default: false

  namespace :web do
    setting :crop_images, default: true
    setting :advanced_layout, default: false
    setting :trends, default: true
    setting :use_blurhash, default: true
    setting :use_pending_items, default: false
    setting :use_system_font, default: false
    setting :disable_swiping, default: false
    setting :delete_modal, default: true
    setting :reblog_modal, default: false
    setting :unfollow_modal, default: true
    setting :favourite_modal, default: false
    setting :reduce_motion, default: false
    setting :expand_content_warnings, default: false
    setting :display_media, default: 'default', in: %w(default show_all hide_all)
    setting :auto_play, default: false
    setting :use_system_emoji_font, default: false
  end

  namespace :notification_emails do
    setting :follow, default: true
    setting :reblog, default: false
    setting :favourite, default: false
    setting :mention, default: true
    setting :follow_request, default: true
    setting :report, default: true
    setting :pending_account, default: true
    setting :trends, default: true
    setting :link_trends, default: false
    setting :status_trends, default: false
    setting :appeal, default: true
  end

  namespace :interactions do
    setting :must_be_follower, default: false
    setting :must_be_following, default: false
    setting :must_be_following_dm, default: false
  end

  def initialize(original_hash)
    @original_hash = original_hash || {}
  end

  def [](key)
    key = key.to_sym

    raise KeyError, "Undefined setting: #{key}" unless self.class.definition_for?(key)

    if @original_hash.key?(key)
      @original_hash[key]
    else
      self.class.definition_for(key).default_value
    end
  end

  def []=(key, value)
    key = key.to_sym

    raise KeyError, "Undefined setting: #{key}" unless self.class.definition_for?(key)

    setting_definition = self.class.definition_for(key)
    typecast_value = setting_definition.type_cast(value)

    raise ArgumentError, "Invalid value for setting #{key}: #{typecast_value}" if setting_definition.in.present? && setting_definition.in.exclude?(typecast_value)

    if typecast_value.nil?
      @original_hash.delete(key)
    else
      @original_hash[key] = typecast_value
    end
  end

  def update(params)
    params.each do |k, v|
      self[k] = v unless v.nil?
    end
  end

  keys.each do |key|
    define_method(key) do
      self[key]
    end
  end

  def as_json
    @original_hash
  end
end
