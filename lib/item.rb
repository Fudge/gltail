# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Item
  attr_accessor :message, :size, :color, :type

  def initialize(message, size, color, type)
    @message = message
    @size = size
    @color = color
    @type = type
  end

end
