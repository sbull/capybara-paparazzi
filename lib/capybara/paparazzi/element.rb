module Capybara::Paparazzi::Element

  def click_with_paparazzi(*args)
    response = click_without_paparazzi(*args)
    Capybara::Paparazzi.take_snapshots_if_following(session.driver, :click, args)
    response
  end

  def self.included(mod)
    mod.send(:alias_method, :click_without_paparazzi, :click)
    mod.send(:alias_method, :click, :click_with_paparazzi)
  end

end
