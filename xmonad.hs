import XMonad
import XMonad.Hooks.SetWMName
import XMonad.Layout.Grid
import XMonad.Layout.ResizableTile
import XMonad.Layout.ThreeColumns
import XMonad.Layout.NoBorders
import XMonad.Layout.Circle
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Layout.Fullscreen
import XMonad.Layout.Tabbed
import XMonad.Util.EZConfig
import XMonad.Util.Run
import XMonad.Hooks.DynamicLog
import XMonad.Actions.Plane
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ICCCMFocus
import XMonad.Config.Desktop
import qualified XMonad.StackSet as W
import qualified Data.Map as M
import Data.Ratio ((%))

myModMask            = mod4Mask
myFocusedBorderColor = "#00cb00"
myNormalBorderColor  = "#cccccc"
myBorderWidth        = 1
myTerminal           = "xterm"
myTitleColor         = "#eeeeee"
myTitleLength        = 30
myCurrentWSColor     = "#e6744c"
myCurrentWSLeft      = "["
myCurrentWSRight     = "]"

myWorkspaces =
  [
    "1", "2", "3", "4",  "5", "6", "7",  "8", "9"
  ]

startupWorkspace = "1"

defaultLayouts = smartBorders(avoidStruts(
  ResizableTall 1 (3/100) (1/2) []
  ||| Mirror (ResizableTall 1 (3/100) (1/2) [])
  ||| noBorders Full
  ||| tabbed shrinkText defaultTheme))
  ||| ThreeColMid 1 (3/100) (1/3)

gimpLayout = smartBorders(avoidStruts(ThreeColMid 1 (3/100) (3/4)))

myLayouts =
  onWorkspace "9" gimpLayout
  $ defaultLayouts

myKeyBindings =
  [
    ((myModMask, xK_b), sendMessage ToggleStruts)
    , ((myModMask, xK_a), sendMessage MirrorShrink)
    , ((myModMask, xK_z), sendMessage MirrorExpand)
    , ((myModMask, xK_x), spawn "synapse")
    , ((myModMask .|. mod1Mask, xK_space), spawn "synapse")
    , ((myModMask .|. shiftMask, xK_t), spawn "xkill")
    , ((myModMask .|. shiftMask, xK_g), spawn "gimp")
    , ((myModMask .|. shiftMask, xK_n), spawn "nautilus --no-desktop")
    , ((0, 0x1008FF12), spawn "amixer -D pulse set Master toggle")
    , ((0, 0x1008FF11), spawn "~/.xmonad/set-volume down")
    , ((0, 0x1008FF13), spawn "~/.xmonad/set-volume up")
    , ((0, 0x1008ffb2), spawn "mictoggle")
    , ((0, 0x1008ff14), spawn "mocp -G")
    , ((0, 0x1008ff30), spawn "gnome-screensaver-command -l")
    , ((0, 0x1008ff02), spawn "xbacklight -inc 7")
    , ((0, 0x1008ff03), spawn "xbacklight -dec 7")
    , ((0, 0x1008ff1d), spawn "gnome-calculator")
    , ((0, xK_Print), spawn "shutter -s")
  ]

myManagementHooks :: [ManageHook]
myManagementHooks = [
  resource =? "synapse" --> doIgnore
  , resource =? "stalonetray" --> doIgnore
  , (className =? "Gimp-2.8") --> doF (W.shift "9")
  ]

numPadKeys =
  [
    xK_KP_Home, xK_KP_Up, xK_KP_Page_Up
    , xK_KP_Left, xK_KP_Begin,xK_KP_Right
    , xK_KP_End, xK_KP_Down, xK_KP_Page_Down
    , xK_KP_Insert, xK_KP_Delete, xK_KP_Enter
  ]

numKeys =
  [
    xK_1, xK_2, xK_3, xK_4, xK_5, xK_6, xK_7, xK_8, xK_9
  ]

myKeys = myKeyBindings ++
  [
    ((m .|. myModMask, k), windows $ f i)
       | (i, k) <- zip myWorkspaces numPadKeys
       , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
  ] ++
  [
    ((m .|. myModMask, k), windows $ f i)
       | (i, k) <- zip myWorkspaces numKeys
       , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
  ] ++
  M.toList (planeKeys myModMask (Lines 4) Finite) ++
  [
    ((m .|. myModMask, key), screenWorkspace sc
      >>= flip whenJust (windows . f))
      | (key, sc) <- zip [xK_w, xK_e, xK_r] [1,0,2]
      , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
  ]

main = do
  xmproc <- spawnPipe "xmobar ~/.xmonad/xmobarrc"
  xmonad $ desktopConfig {
  terminal = myTerminal
  , focusedBorderColor = myFocusedBorderColor
  , normalBorderColor = myNormalBorderColor
  , borderWidth = myBorderWidth
  , layoutHook = desktopLayoutModifiers $ myLayouts
  , workspaces = myWorkspaces
  , modMask = myModMask
  , handleEventHook = handleEventHook desktopConfig
  , startupHook = do
      setWMName "LG3D"
      windows $ W.greedyView startupWorkspace
      spawn "~/.xmonad/startup-hook"
  , manageHook = manageHook desktopConfig
      <+> composeAll myManagementHooks
      <+> manageDocks
  , logHook = takeTopFocus <+> dynamicLogWithPP xmobarPP {
      ppOutput = hPutStrLn xmproc
      , ppTitle = xmobarColor myTitleColor "" . shorten myTitleLength
      , ppCurrent = xmobarColor myCurrentWSColor ""
        . wrap myCurrentWSLeft myCurrentWSRight
    }
  }
    `additionalKeys` myKeys
