import pytest
import asyncio
import os
import sys
import pytest_asyncio

@pytest_asyncio.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()
