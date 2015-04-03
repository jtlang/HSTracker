class Tracker < NSWindowController

  def windowWillMiniaturize(_)
    window.setLevel(NSNormalWindowLevel)
  end

  def windowDidMiniaturize(_)
    window.setLevel(NSScreenSaverWindowLevel)
  end

  def windowDidMove(_)
    save_frame
  end

  def windowDidResize(_)
    save_frame
  end

  def save_frame
    return if Configuration.windows_locked
    NSUserDefaults.standardUserDefaults.setObject(NSStringFromRect(self.window.frame),
                                                  forKey: self.window.identifier)
  end

  def window_locks
    locked = Configuration.windows_locked

    if locked
      mask = NSBorderlessWindowMask
    else
      mask = NSTitledWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
    end
    self.window.setStyleMask mask
  end

  def window_transparency
  end

  def card_layout
    return if @table_view.nil?

    case Configuration.card_layout
      when :small
        row_height = TrackerLayout::KSmallRowHeight
        width      = TrackerLayout::KSmallFrameWidth
      when :medium
        row_height = TrackerLayout::KMediumRowHeight
        width      = TrackerLayout::KMediumFrameWidth
      else
        row_height = TrackerLayout::KRowHeight
        width      = TrackerLayout::KFrameWidth
    end

    frame            = self.window.frame
    frame.size.width = width

    self.window.setFrame(frame, display: true)
    self.window.contentMinSize = [width, 200]
    self.window.contentMaxSize = [width, CGRectGetHeight(NSScreen.mainScreen.frame)]

    @table_view.rowHeight = row_height
    @table_view.reloadData
  end

  def showWindow(sender)
    # trigger when loading the window
    super.tap do
      @option_changed = NSNotificationCenter.defaultCenter.observe 'windows_locked' do |_|
        window_locks
      end

      @transparency_changed = NSNotificationCenter.defaultCenter.observe 'window_transparency' do |_|
        window_transparency
      end

      @card_layout = NSNotificationCenter.defaultCenter.observe 'card_layout' do |_|
        card_layout
      end

      @count_color = NSNotificationCenter.defaultCenter.observe 'count_color' do |_|
        @table_view.reloadData if @table_view
      end

      @count_color_border = NSNotificationCenter.defaultCenter.observe 'count_color_border' do |_|
        @table_view.reloadData if @table_view
      end
    end
  end

  def windowWillClose(_)
    NSNotificationCenter.defaultCenter.unobserve(@option_changed)
    NSNotificationCenter.defaultCenter.unobserve(@transparency_changed)
    NSNotificationCenter.defaultCenter.unobserve(@card_layout)
    NSNotificationCenter.defaultCenter.unobserve(@count_color)
    NSNotificationCenter.defaultCenter.unobserve(@count_color_border)
  end
end