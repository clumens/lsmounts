{-# OPTIONS_GHC -Wall #-}
import Control.Applicative((<$>))
import Data.List(find)
import Data.Maybe(mapMaybe)
import Text.Printf(printf)

data Mountpoint = Mountpoint { mpDevice :: String,
                               mpMount :: String,
                               mpFS :: String,
                               mpOpts :: String,
                               mpFreq :: String,
                               mpPass :: String }

instance Show Mountpoint where
    show mp = printf "%s on %s type %s (%s)" (mpDevice mp) (mpMount mp) (mpFS mp) (mpOpts mp)

-- Convert a string into a list, where each element is a list of all the words
-- on that line.
listify :: String -> [[String]]
listify = map words . lines

-- Given the contents of /proc/filesystems in one big line, return a list of all
-- filesystem types that have an associated device.  This weeds out all the silly
-- crap.
realFilesystems :: String -> [String]
realFilesystems s =
    mapMaybe fsType (listify s)
 where
    -- This is a list of filesystem types that we want to include, even though they
    -- show up as "nodev".
    validAnyway = ["nfs", "nfs4"]

    fsType ["nodev", fs] = find (fs ==) validAnyway
    fsType [fs]          = Just fs
    fsType _             = Nothing

mkMountpoint :: [String] -> Maybe Mountpoint
mkMountpoint [dev, mount, fs, opts, freq, pass] =
    Just $ Mountpoint { mpDevice = dev, mpMount = mount, mpFS = fs, mpOpts = opts, mpFreq = freq, mpPass = pass }
mkMountpoint _ =
    Nothing

-- Given the contents of /proc/mounts in one big line, return a list of Mountpoint
-- records.
getMountpoints :: String -> [Mountpoint]
getMountpoints s =
    mapMaybe mkMountpoint (listify s)

main :: IO ()
main = do
    realFS <- realFilesystems <$> readFile "/proc/filesystems"
    mps <- getMountpoints <$> readFile "/proc/mounts"

    let validMPs = filter (\mp -> mpFS mp `elem` realFS) mps
    mapM_ (putStrLn . show) validMPs
