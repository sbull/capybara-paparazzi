module Capybara::Paparazzi::DSL

  def paparazzi_take_snapshots(*args)
    Capybara::Paparazzi.take_snapshots_if_following(page.driver, :manual, args)
  end

  def self.included(mod)
    unless mod.method_defined?(:take_snapshots)
      mod.send(:alias_method, :take_snapshots, :paparazzi_take_snapshots)
    end
  end

end
