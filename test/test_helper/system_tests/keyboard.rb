# test/test_helper/system_tests/keyboard.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for key presses.
#
# @see Selenium::WebDriver::Keys
# @see Capybara::Node::Element#send_keys
#
module TestHelper::SystemTests::Keyboard

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def press_esc           = send_keys :escape

  def press_home          = send_keys :home
  def press_end           = send_keys :end
  def press_ctrl_home     = send_keys %i[control home]
  def press_ctrl_end      = send_keys %i[control end]

  def press_up            = send_keys :up
  def press_down          = send_keys :down
  def press_left          = send_keys :left
  def press_right         = send_keys :right
  def press_ctrl_up       = send_keys %i[control up]
  def press_ctrl_down     = send_keys %i[control down]
  def press_ctrl_left     = send_keys %i[control left]
  def press_ctrl_right    = send_keys %i[control right]

  def press_pg_up         = send_keys :page_up
  def press_pg_down       = send_keys :page_down
  def press_ctrl_pg_up    = send_keys %i[control page_up]
  def press_ctrl_pg_down  = send_keys %i[control page_down]

  def press_tab           = send_keys :tab
  def press_shift_tab     = send_keys %i[shift tab]

end
