extends RefCounted
class_name Utils

static func gen_uuid() -> String:
    return "%08x" % randi()