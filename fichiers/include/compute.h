
#ifndef COMPUTE_IS_DEF
#define COMPUTE_IS_DEF

#include <stdbool.h>

typedef void (*void_func_t) (void);
typedef unsigned (*int_func_t) (unsigned);

extern void_func_t first_touch [];
extern void_func_t init [];
extern int_func_t compute [];
extern char *version_name [];
extern unsigned opencl_used [];


extern int nb_tiles;
extern bool** tile_changed;

extern unsigned version;


#endif
