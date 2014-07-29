module Capybara::Paparazzi::Driver

  def visit(*args)
    response = super(*args)
    Capybara::Paparazzi.take_snapshots(self, :visit, args)
    response
  end

end
