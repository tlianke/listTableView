#include "aiengine.h"

AIENGINE_IMPORT_OR_EXPORT struct aiengine * AIENGINE_CALL aiengine_new(const char *cfg)
{
    return 0x0000;
}

AIENGINE_IMPORT_OR_EXPORT int AIENGINE_CALL aiengine_delete(struct aiengine *engine)
{
    return 1;
}

AIENGINE_IMPORT_OR_EXPORT int AIENGINE_CALL aiengine_start(struct aiengine *engine, const char *param, char id[64], aiengine_callback callback, const void *usrdata)
{
    return 1;
}

AIENGINE_IMPORT_OR_EXPORT int AIENGINE_CALL aiengine_feed(struct aiengine *engine, const void *data, int size)
{
    return 1;
}

AIENGINE_IMPORT_OR_EXPORT int AIENGINE_CALL aiengine_stop(struct aiengine *engine)
{
    return 1;
}

AIENGINE_IMPORT_OR_EXPORT int AIENGINE_CALL aiengine_log(struct aiengine *engine, const char *log)
{
    return 1;
}

AIENGINE_IMPORT_OR_EXPORT int AIENGINE_CALL aiengine_get_device_id(char device_id[64])
{
    return 1;
}

AIENGINE_IMPORT_OR_EXPORT int AIENGINE_CALL aiengine_cancel(struct aiengine *engine)
{
    return 1;
}

AIENGINE_IMPORT_OR_EXPORT int AIENGINE_CALL aiengine_opt(struct aiengine *engine, int opt, char *data, int size)
{
    return 1;
}