module Capybara::Paparazzi::Driver

  # TODO: go_back, go_forward

  def visit(*args)
    super(*args)
    take_snapshots(:visit, args)
  end

  def take_snapshots(method, args)
    Capybara::Paparazzi.take_snapshots(self, { method: method, args: args })
  end

end
