
#include "compute.h"
#include "graphics.h"
#include "debug.h"
#include "ocl.h"

#include <stdbool.h>

#define RED_MASK	0XFF000000
#define GREEN_MASK	0x00FF0000
#define BLUE_MASK	0x0000FF00
#define ALPHA_MASK	0x000000FF
#define WHITE		0xFFFFFFFF
#define BLACK		0x00000000
#define RED			0xFF0000FF
#define GREEN		0x00FF00FF
#define BLUE		0x0000FFFF
#define YELLOW		0xFFFF00FF
#define CYAN		0x00FFFFFF
#define MAGENTA		0xFF00FFFF

#define TILE 32


unsigned version = 0;

void first_touch_v1 (void);
void first_touch_v2 (void);

unsigned compute_v0 (unsigned nb_iter);
unsigned compute_v1 (unsigned nb_iter);
unsigned compute_v2 (unsigned nb_iter);
unsigned compute_v3 (unsigned nb_iter);
unsigned compute_v4 (unsigned nb_iter);
unsigned compute_v5 (unsigned nb_iter);
unsigned compute_v6 (unsigned nb_iter);
unsigned compute_v7 (unsigned nb_iter);
unsigned compute_v8 (unsigned nb_iter);
unsigned compute_v9 (unsigned nb_iter);
unsigned compute_v10 (unsigned nb_iter);


void_func_t first_touch [] = { // TODO
	NULL, 				// sequential base
	first_touch_v1, 	// sequential tiled
	first_touch_v2, 	// sequential optimized
	NULL, 				// OpenMP for base
	NULL, 				// OpenMP for tiled
	NULL, 				// OpenMP for optimized
	NULL, 				// OpenMP task tiled
	NULL, 				// OpenMP task optimized
	NULL, 				// OpenCl base
	NULL, 				// OpenCl optimize
	NULL 				// OpenCl + OpenMP
};

int_func_t compute [] = {
	compute_v0, 	// sequential base
	compute_v1, 	// sequential tiled
	compute_v2, 	// sequential optimized
	compute_v3, 	// OpenMP for base
	compute_v4, 	// OpenMP for tiled
	compute_v5, 	// OpenMP for optimized
	compute_v6, 	// OpenMP task tiled
	compute_v7, 	// OpenMP task optimized
	compute_v8, 	// OpenCl base
	compute_v9, 	// OpenCl optimize
	compute_v10 	// OpenCl + OpenMP
};

char *version_name [] = {
	"Séquentielle base",
	"Séquentielle tuilée",
	"Séquentielle optimisée",
	"OpenMP for base",
	"OpenMP for tuilée",
	"OpenMP for optimisée",
	"OpenMP task tuilée",
	"OpenMP task optimisée",
	"OpenCL base",
	"OpenCL optimisée",
	"Mixte OpenCL + OpenMP"
};


unsigned opencl_used [] = {
	0, 		// sequential base
	0, 		// sequential tiled
	0, 		// sequential optimized
	0, 		// OpenMP for base
	0, 		// OpenMP for tiled
	0, 		// OpenMP for optimized
	0, 		// OpenMP task tiled
	0, 		// OpenMP task optimized
	1, 		// OpenCl base
	1, 		// OpenCl optimize
	1 		// OpenCl + OpenMP
};

/*
 * Calcule le prochain état d'une la cellule à la position (i,j)
 * Retourne vrai si l'état a changé, faux sinon.
 */
static inline bool change_state (unsigned i, unsigned j)
{
	unsigned short count = 0;

	if (cur_img(i-1, j-1)) count++;
	if (cur_img(i-1, j)) count++;
	if (cur_img(i-1, j+1)) count++;
	if (cur_img(i, j-1)) count++;
	if (cur_img(i, j+1)) count++;
	if (cur_img(i+1, j-1)) count++;
	if (cur_img(i+1, j)) count++;
	if (cur_img(i+1, j+1)) count++;

	if (cur_img(i, j)){
		if (count == 2 || count == 3 )
			next_img(i, j) = YELLOW;
		else
			next_img(i, j) = 0;
	} else {
		if (count == 3 )
			next_img(i, j) = RED;
		else
			next_img(i, j) = 0;
	}
	return (ALPHA_MASK & cur_img(i, j)) != (ALPHA_MASK & next_img(i, j));
}

///////////////////////////// Version 0 : séquentielle de base

/*
 * Retourne le nombre d'étapes nécessaires à la stabilisation
 * du calcul ou bien 0 si le calcul n'est pas stabilisé au bout
 * des nb_iter itérations
 */
unsigned compute_v0 (unsigned nb_iter)
{
	bool change = true;
	unsigned it;
	for (it = 1; it <= nb_iter && change; it++) {
		change = false;
		for (int i = 1; i < DIM-1; ++i)
			for (int j = 1; j < DIM-1; ++j)
				if (change_state(i,j))
					change = true;
		 // next_img (i, j) = cur_img (j, i);
		swap_images ();
	}
	return change ? 0 : it;
}

///////////////////////////// Version 1 : séquentielle tuilée

unsigned compute_v1 (unsigned nb_iter)
{
	bool change = true;
	unsigned it;
	for (it = 1; it <= nb_iter && change; ++it) {
		change = false;
		for (unsigned i = 1; i < DIM-1; i += TILE)
			for (unsigned j = 1; j < DIM-1; j += TILE) {
				for (unsigned i2 = i, end_tile_i = MIN(i + TILE, DIM-1); i2 < end_tile_i; ++i2)
					for (unsigned j2 = j, end_tile_j = MIN(j + TILE, DIM-1); j2 < end_tile_j; ++j2)
						if (change_state(i2, j2))
							change = true;
			}
		swap_images ();
  }
  return change ? 0 : it;
}

///////////////////////////// Version 2 : séquentielle optimisée

unsigned compute_v2 (unsigned nb_iter)
{
	return 0;
}

///////////////////////////// Version 3 : OpenMP de base

void first_touch_v1 ()
{
 	int i,j;

	#pragma omp parallel for
	for(i = 0; i < DIM ; i++) {
		for(j = 0; j < DIM ; j += 512)
			next_img (i, j) = cur_img (i, j) = 0 ;
	}
}

// Renvoie le nombre d'itérations effectuées avant stabilisation, ou 0
unsigned compute_v3 (unsigned nb_iter)
{
	bool change = true;
	unsigned it;
	for (it = 1; it <= nb_iter && change; ++it) {
		change = false;
		#pragma omp parallel for schedule(static) // collapse(2)
		for (int i = 1; i < DIM-1; ++i)
			for (int j = 1; j < DIM-1; ++j)
				if (change_state(i, j))
					change = true;
		swap_images ();
	}
	return change ? 0 : it; // 0 si on ne s'arrête jamais
}

///////////////////////////// Version 4 : OpenMP tuilée

// Renvoie le nombre d'itérations effectuées avant stabilisation, ou 0
unsigned compute_v4 (unsigned nb_iter)
{
	bool change = true;
	unsigned it;
	for (it = 1; it <= nb_iter && change; ++it) {
		change = false;
		#pragma omp parallel for collapse(2) schedule(static)
		for (unsigned i = 1; i < DIM-1; i += TILE)
			for (unsigned j = 1; j < DIM-1; j += TILE) {
				for (unsigned i2 = i, end_tile_i = MIN(i + TILE, DIM-1); i2 < end_tile_i; ++i2)
					for (unsigned j2 = j, end_tile_j = MIN(j + TILE, DIM-1); j2 < end_tile_j; ++j2)
						if (change_state(i2, j2))
							change = true;
			}
		swap_images ();
	}
	return change ? 0 : it;
}


///////////////////////////// Version 5 : OpenMP optimisée

void first_touch_v2 ()
{

}

// Renvoie le nombre d'itérations effectuées avant stabilisation, ou 0
unsigned compute_v5 (unsigned nb_iter)
{
	return 0; // on ne s'arrête jamais
}

///////////////////////////// Version OpenMP task tuilée

unsigned compute_v6 (unsigned nb_iter)
{
	bool change = true;
	unsigned it;
	for (it = 1; it <= nb_iter && change; ++it) {
		change = false;
		#pragma omp parallel
		//#pragma omp for collapse(2) schedule(static)
		for (unsigned i = 1; i < DIM-1; i += TILE)
			for (unsigned j = 1; j < DIM-1; j += TILE) {
				#pragma omp single nowait
				#pragma omp task shared(change)
				{
					for (unsigned i2 = i, end_tile_i = MIN(i + TILE, DIM-1); i2 < end_tile_i; ++i2)
						for (unsigned j2 = j, end_tile_j = MIN(j + TILE, DIM-1); j2 < end_tile_j; ++j2)
							if (change_state(i2, j2))
								change = true;
				}
			}
		swap_images ();
	}

	return change ? 0 : it;
}

///////////////////////////// Version OpenMP task optimisée

unsigned compute_v7 (unsigned nb_iter){
 return 0;
}


///////////////////////////// Version OpenCL
// Renvoie le nombre d'itérations effectuées avant stabilisation, ou 0
unsigned compute_v8 (unsigned nb_iter){
	return ocl_compute (nb_iter);
}

unsigned compute_v9 (unsigned nb_iter){
 return 0;
}

///////////////////////////// Version OpenCL + OpenMP
unsigned compute_v10 (unsigned nb_iter){
 return nb_iter;
}
