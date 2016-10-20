# Allow usage on Vagrant
if defined? BetterErrors
  # Opening files
  BetterErrors.editor = proc { |full_path, line|
    full_path = full_path.sub(Rails.root.to_s, ENV["VAGRANT_HOST_PATH"])
    "subl://open?url=file://#{full_path}&line=#{line}"
  }

  # Allowing host
  host = ENV["SSH_CLIENT"] ? ENV["SSH_CLIENT"].match(/\A([^\s]*)/)[1] : nil
  BetterErrors::Middleware.allow_ip! host if [:development, :test].member?(Rails.env.to_sym) && host
end
