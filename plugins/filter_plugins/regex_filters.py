# -*- coding: utf-8 -*-
import re
import traceback

from ansible.module_utils._text import to_text
from ansible.utils.unsafe_proxy import AnsibleUnsafeText


class FilterModule(object):
    def filters(self: object):
        return {
            'capture_group': capture_group,
        }


def capture_group(text: AnsibleUnsafeText, re_pattern: str, group=0) -> str:
    """Returns specified group captured with regex expression. Will return empty string if nothing was captured."""
    match_group = ''
    try:
        match_group = re.search(re_pattern, str(text)).group(group)
    except AttributeError as ae:
        print(type(ae).__name__)
        traceback.print_stack()
    return to_text(match_group)
