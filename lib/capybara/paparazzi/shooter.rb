class Capybara::Paparazzi::Shooter

  DEFAULT_SCREENSHOT_SIZES =
    [
     [ 320, 444 ], # 568 - 124
     [ 768, 900 ], # 1024 - 124
     [ 1024, 644 ], # 768 - 124
     [ 1336, 600 ],
    ].freeze

  DEFAULT_FOLD_STYLE = {
    position: 'fixed',
    top: '0',
    left: '0',
    width: '100%',
    zIndex: 999999,
    borderBottom: '1px solid red',
  }.freeze

  CONFIG_VARS = {
    js_var_name: 'THE_FOLD',
    js_var_style: {}.merge(DEFAULT_FOLD_STYLE),
    screenshot_sizes: ([] + DEFAULT_SCREENSHOT_SIZES),
    file_dir: 'screenshots',
    js_setup_script: ->(shooter) {
      var_name = shooter.js_var_name
      script = "if (!window.#{var_name}) { #{var_name} = document.createElement('DIV');"
      shooter.js_var_style.each do |prop_name, prop_val|
        script += "#{var_name}.style.#{prop_name} = #{prop_val.to_json};"
      end
      script += "} document.body.appendChild(#{var_name});"
    },
    js_resize_script: ->(shooter, height) { "#{shooter.js_var_name}.style.height = '#{height}px';" },
    before_save_callback: nil,
    js_cleanup_script: ->(shooter) { "document.body.removeChild(#{shooter.js_var_name});" },
  }.freeze


  module ClassMethods

    attr_accessor(*CONFIG_VARS.keys)

    def config
      @_configged ||=
        begin
          CONFIG_VARS.each do |cv, default|
            send("#{cv}=".to_sym, default)
            true
          end
        end
      if block_given?
        yield(self)
      end
    end

    def use(*args)
      Capybara::Paparazzi.use(*args)
    end

    def take_snapshots(driver, event_details=nil)
      # TODO: Be smarter. One shooter per driver, but avoid memory leaks (be mindful of Guard, etc.).
      new(driver, event_details).take_snapshots
    end

    def next_suffix_for_path!(path)
      # TODO: Be smarter about this - multi-threaded, etc.
      @path_nums ||= {}
      num = @path_nums[path]
      @path_nums[path] = num.to_i + 1
      if num
        suffix = ".#{num}"
        if @path_nums[path+suffix]
          suffix = next_suffix_for_path!(path)
        end
      else
        suffix = ''
      end
      suffix
    end

  end # ClassMethods

  extend ClassMethods


  attr_accessor :driver, :event_details
  attr_accessor :path, :suffix
  attr_accessor :do_shot, :screenshot_size, :filename
  attr_accessor :before_save_callback

  attr_accessor(*CONFIG_VARS.keys)
  # def cv; @cv ||= self.class.config[:cv]; end
  CONFIG_VARS.each do |cv, default|
    define_method(cv) do
      iv_sym = "@#{cv}".to_sym
      iv = instance_variable_get(iv_sym)
      unless iv
        iv = self.class.send(cv.to_sym)
        instance_variable_set(iv_sym, iv)
      end
      iv
    end
  end


  def initialize(driver, event_details=nil)
    @driver = driver
    @event_details = event_details
    @config = self.class.config
  end

  def take_snapshots
    set_path_and_suffix
    execute_setup_script
    save_snapshots
    execute_cleanup_script
  end

  def width
    @screenshot_size[0]
  end

  def height
    @screenshot_size[1]
  end

  def resize_window(width, height)
    begin
      if driver.respond_to?(:resize) # Poltergeist
        driver.resize(width, height)
      elsif driver.respond_to?(:resize_window) # Poltergeist
        driver.resize_window(width, height)
      else # Capybara default / Selenium
        driver.resize_window_to(driver.current_window_handle, width, height)
      end
    rescue => e
      log("Error while resizing window: #{e}")
    end
    execute_resize_script(height)
  end


  private

  def set_path_and_suffix
    path, suffix = path_and_suffix_for_url(driver.current_url)
    self.path = path
    self.suffix = suffix
  end

  def execute_setup_script
    exec_js(:js_setup_script, self)
  end

  def exec_js(script_name, *args)
    begin
      script = send(script_name)
      if script
        script_text = script.is_a?(Proc) ? script.call(*args) : script.to_s
        driver.execute_script(script_text)
      end
    rescue => e
      log("#{e.message}\nJavascript: #{script_text}")
    end
  end

  def save_snapshots
    screenshot_sizes.each do |w_h_rest|
      save_snapshot(w_h_rest)
    end
  end

  def save_snapshot(width_height_rest)
    @do_shot = true
    @screenshot_size = ([] + width_height_rest)
    @filename = "#{file_dir}#{path}#{suffix}-#{width}.png"

    resize_window(width, height)

    before_save_callback.call(self) if before_save_callback

    if @do_shot
      save_screenshot
    end
  end

  def execute_resize_script(height)
    exec_js(:js_resize_script, self, height)
  end

  def execute_cleanup_script
    exec_js(:js_cleanup_script, self)
  end

  def save_screenshot
    driver.save_screenshot(*get_save_screenshot_args)
  end

  def get_save_screenshot_args
    [ filename, { full: true } ]
  end

  def path_and_suffix_for_url(url)
    path = URI.parse(url).path
    path += 'index' if path[-1] == '/'
    suffix = next_suffix_for_path!(path)
    [ path, suffix ]
  end

  def next_suffix_for_path!(path)
    self.class.next_suffix_for_path!(path)
  end

  def log(msg)
    warn "Capybara::Paparazzi: #{msg}"
  end

end
