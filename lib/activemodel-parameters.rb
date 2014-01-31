require 'active_model'

require 'active_model/parameters'
require 'active_model/parameters/railtie' if defined?(Rails)

begin
  require 'action_controller'
  require 'action_controller/parameterization'

  ActiveSupport.on_load(:action_controller) do
    include ::ActionController::Parameterization
  end
rescue LoadError
  # rails not installed, continuing
end
