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
    background: 'none',
    borderBottom: '3px dashed red',
  }.freeze

  CONFIG_VARS = {
    js_var_name: 'CAPYBARA_PAPARAZZI_FOLD',
    js_var_style: {}.merge(DEFAULT_FOLD_STYLE),
    screenshot_sizes: ([] + DEFAULT_SCREENSHOT_SIZES),
    file_dir: 'screenshots',
    make_fewer_directories: false,
    make_shorter_filenames: false,
    path_and_suffix_generator: ->(shooter, url) {
      shooter.path_and_suffix_for_url(url)
    },
    js_setup_script: ->(shooter) {
      var_name = shooter.js_var_name
      script = "if (!window.#{var_name}) { #{var_name} = document.createElement('DIV'); #{var_name}.className = '#{var_name}';"
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

    def follow(*args)
      Capybara::Paparazzi.follow(*args)
    end

    def take_snapshots(driver, event_details=nil)
      # TODO: Be smarter. One shooter per driver, but avoid memory leaks (be mindful of Guard, etc.).
      unless driver.capybara_paparazzi_settings[:block_disabled] || driver.capybara_paparazzi_settings[:manually_disabled]
        new(driver, event_details).take_snapshots
      end
    end

    def without_snapshots(driver, &block)
      is_paparazzi = is_paparazzi?(driver)
      if is_paparazzi
        old_val = driver.capybara_paparazzi_settings[:block_disabled]
        driver.capybara_paparazzi_settings[:block_disabled] = true
      end
      begin
        yield
      ensure
        if is_paparazzi
          driver.capybara_paparazzi_settings[:block_disabled] = old_val
        end
      end
    end

    def turn_off(driver)
      if is_paparazzi?(driver)
        driver.capybara_paparazzi_settings[:manually_disabled] = true
      end
    end

    def turn_on(driver)
      if is_paparazzi?(driver)
        driver.capybara_paparazzi_settings[:manually_disabled] = false
      end
    end

    def is_paparazzi?(driver)
      driver.is_a?(Capybara::Paparazzi::Driver)
    end

    def next_suffix_for_path!(path)
      # TODO: Be smarter about this - multi-threaded, etc.
      @path_nums ||= {}
      num = @path_nums[path]
      @path_nums[path] = num.to_i + 1
      if num
        suffix = "-#{num}"
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
    driver_resize_window(width, height)
    execute_resize_script(height)
  end

  def path_and_suffix_for_url(url)
    path = URI.parse(url).path
    path[0] = '' # remove the leading '/'
    path[-1] = '' if path[-1] == '/' # remove the trailing '/'
    path = 'index' if path.empty?
    base = path.gsub('/','-')
    if make_fewer_directories
      unless make_shorter_filenames
        path = path.sub(/[^\/]*$/, '') + base
      end
    else
      path += '/'
      unless make_shorter_filenames
        path += base
      end
    end
    suffix = next_suffix_for_path!(path)
    [ path, suffix ]
  end


  private

  def set_path_and_suffix
    path, suffix = path_and_suffix_generator.call(self, driver.current_url)
    self.path = path
    self.suffix = suffix
  end

  def driver_resize_window(width, height)
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
      raise
    end
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
      raise
    end
  end

  def save_snapshots
    # In some cases, using screen sizes other than the default
    # can cause failures in Poltergeist, when using the default
    # screen size does not. So be sure to always reset to the
    # original screen size to ensure test behavior consistent with
    # the non-Capybara::Paparazzi tests.
    # Example error:
    # Firing a click at co-ordinates [703, 654] failed. Poltergeist detected another element with CSS selector '' at this position. It may be overlapping the element you are trying to interact with. If you don't care about overlapping elements, try using node.trigger('click').

    begin
      orig_width, orig_height = driver.evaluate_script("[window.innerWidth, window.innerHeight]")
      screenshot_sizes.each do |w_h_rest|
        save_snapshot(w_h_rest)
      end
    ensure
      begin
        driver_resize_window(orig_width, orig_height)
      rescue => e
        log("Error restoring original window size to #{orig_width}x#{orig_height}: #{e}")
      end
    end
  end

  def save_snapshot(width_height_rest)
    @do_shot = true
    @screenshot_size = ([] + width_height_rest)

    @filename = "#{file_dir}/#{path}"
    @filename += '-' unless @filename[-1] == '/'
    @filename += "#{width}#{suffix}.png"

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

  def next_suffix_for_path!(path)
    self.class.next_suffix_for_path!(path)
  end

  def log(msg)
    warn "Capybara::Paparazzi: #{msg}"
  end

end
