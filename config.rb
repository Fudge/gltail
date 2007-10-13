#ENV['__GL_SYNC_TO_VBLANK']="1"
$WINDOW_WIDTH = 1200
$WINDOW_HEIGHT = 760

$COLUMN_SIZE_LEFT  = 25 # in characters, will be truncated
$COLUMN_SIZE_RIGHT = 25 # in characters, will be truncated

$RIGHT_COL = 0.99
$LEFT_COL = -0.99

$MIN_BLOB_SIZE = 0.004
$MAX_BLOB_SIZE = 0.04

# File which to load servers config from. Default is servers.yaml

$SERVER_YAML_FILE = 'servers.yaml'

# Sections with different information to display on the screen, will be hidden unless they get any activity
$BLOCKS = [
           { :name => 'info',          :position => :left,  :order => 0, :size => 10, :auto_clean => false, :show => :total },
           { :name => 'hosts',         :position => :left,  :order => 1, :size => 3  },
           { :name => 'sites',         :position => :left,  :order => 2, :size => 10 },
           { :name => 'content',       :position => :left,  :order => 3, :size => 5,  :show => :total, :color => [1.0, 0.8, 0.4, 1.0] },
           { :name => 'status',        :position => :left,  :order => 4, :size => 10, :color => [1.0, 0.8, 0.4, 1.0] },
           { :name => 'types',         :position => :left,  :order => 5, :size => 5,  :color => [1.0, 0.4, 0.2, 1.0] },
           { :name => 'users',         :position => :left,  :order => 6, :size => 10 },
           { :name => 'smtp',          :position => :left,  :order => 7, :size => 5  },
           { :name => 'logins',        :position => :left,  :order => 8, :size => 5  },
           { :name => 'database',      :position => :left,  :order => 9, :size => 10 },

           { :name => 'urls',          :position => :right, :order => 0, :size => 15 },
           { :name => 'slow requests', :position => :right, :order => 1, :size => 5, :show => :average },
           { :name => 'referrers',     :position => :right, :order => 2, :size => 10 },
           { :name => 'user agents',   :position => :right, :order => 3, :size => 5, :color => [1.0, 1.0, 1.0, 1.0] },
           { :name => 'mail from',     :position => :right, :order => 4, :size => 5  },
           { :name => 'mail to',       :position => :right, :order => 5, :size => 5  },
           { :name => 'viruses',       :position => :right, :order => 6, :size => 5  },
           { :name => 'rejections',    :position => :right, :order => 7, :size => 5, :color => [1.0, 0.2, 0.2, 1.0]  },
           { :name => 'warnings',      :position => :right, :order => 8, :size => 5  },
          ]
