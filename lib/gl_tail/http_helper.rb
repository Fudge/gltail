# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class HttpHelper

  def self.parse_useragent(ua)
    case ua
    when /MSIE ([^;]+);/
      "Internet Explorer #{$1}"
    when /Firefox\/(\S+)/
      "Firefox #{$1}"
    when /Iceweasel\/(\S+)/
      "Firefox #{$1}"
    when /Shiretoko\/(\S+)/
      "Firefox #{$1}"
    when /Camino\/(\S+)/
      "Camino #{$1}"
    when /Opera\/(\S+)/
      "Opera #{$1}"
    when /Chrome\/([\d.]+)/
      "Chrome #{$1}"
    when /Safari\/([\d.]+)/
      "Safari #{$1}"
    when /Galeon\/([\d.]+)/
      "Galeon #{$1}"
    when /Konqueror\/(\S+);/
      "Konqueror #{$1}"
    when /Wget/
      'Wget'

    when /ia_archiver/
      "Internet Archive Bot"
    when /Googlebot/
      "Google Bot"
    when /Feedfetcher-Google/
      "Google Feeds"
    when /msnbot-media/
      "Microsoft Media Bot"
    when /msnbot/
      "Microsoft Bot"
    when /Gigabot/
      'Gigabot'
    when /Yahoo!/
      'Yahoo Bot'
    when "-"
      "-"
    else
      ua
    end
  end

  def self.generalize_url(url)
    case url
    when /^(.*?)\/(\d+)$/
      "#{$1}/:id"
    when /^(.*?)\/[a-zA-Z0-9]{32}(.*?)$/
      "#{$1}/:md5#{$2 if $2}"
    else
      url
    end
  end

end
