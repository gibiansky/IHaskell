{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeSynonymInstances #-}

{-# OPTIONS_GHC -fno-warn-orphans  #-}

module IHaskell.Display.Widgets.Button
  ( -- * The Button Widget
    Button
    -- * Create a new button
  , mkButton
  ) where

-- To keep `cabal repl` happy when running from the ihaskell repo
import           Prelude

import           Data.Aeson
import           Data.IORef (newIORef)
import           Data.Vinyl (Rec(..), (<+>))

import           IHaskell.Display
import           IHaskell.Eval.Widgets
import           IHaskell.IPython.Message.UUID as U

import           IHaskell.Display.Widgets.Types
import           IHaskell.Display.Widgets.Common

-- | A 'Button' represents a Button from IPython.html.widgets.
type Button = IPythonWidget 'ButtonType

-- | Create a new button
mkButton :: IO Button
mkButton = do
  -- Default properties, with a random uuid
  wid <- U.random

  let dom = defaultDOMWidget "ButtonView" "ButtonModel"
      but = (Description =:: "")
            :& (Tooltip =:: "")
            :& (Disabled =:: False)
            :& (Icon =:: "")
            :& (ButtonStyle =:: DefaultButton)
            :& (ClickHandler =:: return ())
            :& RNil
      buttonState = WidgetState (dom <+> but)

  stateIO <- newIORef buttonState

  let button = IPythonWidget wid stateIO

  -- Open a comm for this widget, and store it in the kernel state
  widgetSendOpen button $ toJSON buttonState

  -- Return the button widget
  return button

instance IHaskellDisplay Button where
  display b = do
    widgetSendView b
    return $ Display []

instance IHaskellWidget Button where
  getCommUUID = uuid
  comm widget val _ =
    case nestedObjectLookup val ["content", "event"] of
      Just (String "click") -> triggerClick widget
      _ -> pure ()
