
# req is a little help Struct to combine all the variables into one
def my_events(req)  
  # my login action redirects on success, 200 on validation/login failure (for posts)
  add_event("info", "Login " + (req.code == 302) ? "Success" : "Failure") if req.post? and req.url == "/user/login"
  
  # none of the custom events in apache.rb work for my site (besides login)
  # so this would be a real nice easy way to hook into that process
end

class SomeOddParser < GlTail::Parser
  def parse(line)
    if line =~ /something-really-wicked/
      add_event("wicked", "crazy")
    end
  end
end


##
## OPTION #1
##
gltail.configure do |cfg|

  cfg.add_server("site1") do |srv|
    srv.host("foo@foobar.com") # () would be optional
    srv.host = "foo@foobar.com" # use standard setters
    
    srv.command("tail -f -n0 /var/log/apache/access_log")
    srv.parser("apache") do |p|
      p.add_callback(method(:my_events))
    end
    
    srv.parser(SomeOddParser) # for complete custom parsers
  end
end

  
##
## OPTION #2
##  
gltail.configure do |cfg|

  cfg.add_server("site1", {
    :host  => "foo@foobar.com",
    :command => "tail -f -n0 /var/log/apache/access_log",
    :parser  => {
      :type => "apache",
      :add_callback => method(:my_events)
    }
  })
end

##
## OPTION #3
##

server "site1" do
  host("foo@foobar.com") # host = bla is invalid since its a local variable which is inaccessible, () still optional tho
  command("tail -f -n0 /var/log/apache/access_log")
  parser("apache") do
    callback method(:my_event)
  end
end

region "screen" do
  dimensions(1600, 1200)
  
  block("info") do
    max_size(5)
    location(400, 300) # relativ to region coord space
    dimensions(200, 100)
  end
end