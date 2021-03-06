#ifndef OCL_IS_DEF
#define OCL_IS_DEF


#include <SDL_opengl.h>

void ocl_init (void);
void ocl_map_textures (GLuint texid);
void ocl_send_image (unsigned *image);
unsigned ocl_compute (unsigned nb_iter);
void ocl_wait (void);
void ocl_update_texture (void);

unsigned ocl_base(unsigned nb_iter);
unsigned ocl_optimized(unsigned nb_iter);

extern unsigned SIZE, TILE;

#endif
