"""SeraphLabs Core contracts"""

try:
  from importlib import metadata as importlib_metadata
except ImportError:
  import importlib_metadata

try:
  __version__ = importlib_metadata.version("seraphlabs-cairo-contracts")
except importlib_metadata.PackageNotFoundError:
  __version__ = None