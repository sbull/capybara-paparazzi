module Capybara::Paparazzi::DSL

  def paparazzi_take_snapshots(*args)
    Capybara::Paparazzi.take_snapshots_if_following(page.driver, :manual, args)
  end

  def turn_paparazzi_off
    Capybara::Paparazzi.turn_off(page.driver)
  end

  def turn_paparazzi_on
    Capybara::Paparazzi.turn_on(page.driver)
  end

  def without_paparazzi(&block)
    Capybara::Paparazzi.without_snapshots(page.driver) do
      yield
    end
  end

  def self.included(mod)
    [
     [ :paparazzi_take_snapshots, :take_snapshots ],
     [ :without_paparazzi, :without_snapshots ],
     [ :turn_paparazzi_off, :turn_snapshots_off ],
     [ :turn_paparazzi_on, :turn_snapshots_on ],
    ].each do |meth, aka|
      mod.send(:alias_method, aka, meth) unless mod.method_defined?(aka)
    end
  end

end
