# frozen_string_literal: true

module AccountsHelper
  def display_name(account, **options)
    str = account.display_name.presence || account.username

    if options[:custom_emojify]
      prerender_custom_emojis(h(str), account.emojis)
    else
      str
    end
  end

  def acct(account)
    if account.local?
      "@#{account.acct}@#{site_hostname}"
    else
      "@#{account.pretty_acct}"
    end
  end

  def account_action_button(account)
    return if account.memorial? || account.moved?

    link_to ActivityPub::TagManager.instance.url_for(account), class: 'button logo-button', target: '_new' do
      safe_join([logo_as_symbol, t('accounts.follow')])
    end
  end

  def hide_followers_count?(account)
    Setting.hide_followers_count || account.user&.settings&.[]('hide_followers_count')
  end

  def account_formatted_stat(value)
    number_to_human(value, precision: 3, strip_insignificant_zeros: true)
  end

  def account_description(account)
    prepend_stats = [
      [
        account_formatted_stat(account.statuses_count),
        I18n.t('accounts.posts', count: account.statuses_count),
      ].join(' '),

      [
        account_formatted_stat(account.following_count),
        I18n.t('accounts.following', count: account.following_count),
      ].join(' '),
    ]

    unless hide_followers_count?(account)
      prepend_stats << [
        account_formatted_stat(account.followers_count),
        I18n.t('accounts.followers', count: account.followers_count),
      ].join(' ')
    end

    [prepend_stats.join(', '), account.note].join(' · ')
  end
end
