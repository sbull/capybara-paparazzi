module Capybara::Paparazzi::Element

  def click_with_paparazzi(*args)
    response = click_without_paparazzi(*args)
    if session.driver.respond_to?(:take_snapshots)
      session.driver.take_snapshots(:click, args)
    end
    response
  end

  def self.included(mod)
    mod.send(:alias_method, :click_without_paparazzi, :click)
    mod.send(:alias_method, :click, :click_with_paparazzi)
  end

end
