import pytest
from main import get_links


def test_get_links():
    assert get_links('https://www.google.com/gmail/sitemap.xml') == type(dict())