#define RED_MASK 	0XFF000000
#define GREEN_MASK 	0x00FF0000
#define BLUE_MASK 	0x0000FF00
#define ALPHA_MASK 	0x000000FF
#define WHITE 		0xFFFFFFFF
#define BLACK 		0x00000000
#define RED 		0xFF0000FF
#define GREEN 		0x00FF00FF
#define BLUE 		0x0000FFFF
#define YELLOW 		0xFFFF00FF
#define CYAN 		0x00FFFFFF
#define MAGENTA 	0xFF00FFFF

__kernel void transpose_naif (__global unsigned *in, __global unsigned *out)
{
  int x = get_global_id (0);
  int y = get_global_id (1);

  out [x * DIM + y] = in [y * DIM + x];
}



__kernel void transpose (__global unsigned *in, __global unsigned *out)
{
  __local unsigned tile [TILEX][TILEY+1];
  int x = get_global_id (0);
  int y = get_global_id (1);
  int xloc = get_local_id (0);
  int yloc = get_local_id (1);

  tile [xloc][yloc] = in [y * DIM + x];

  barrier (CLK_LOCAL_MEM_FENCE);

  out [(x - xloc + yloc) * DIM + y - yloc + xloc] = tile [yloc][xloc];
}



// NE PAS MODIFIER
static unsigned color_mean (unsigned c1, unsigned c2)
{
  uchar4 c;

  c.x = ((unsigned)(((uchar4 *) &c1)->x) + (unsigned)(((uchar4 *) &c2)->x)) / 2;
  c.y = ((unsigned)(((uchar4 *) &c1)->y) + (unsigned)(((uchar4 *) &c2)->y)) / 2;
  c.z = ((unsigned)(((uchar4 *) &c1)->z) + (unsigned)(((uchar4 *) &c2)->z)) / 2;
  c.w = ((unsigned)(((uchar4 *) &c1)->w) + (unsigned)(((uchar4 *) &c2)->w)) / 2;

  return (unsigned) c;
}

// NE PAS MODIFIER
static int4 color_to_int4 (unsigned c)
{
  uchar4 ci = *(uchar4 *) &c;
  return convert_int4 (ci);
}

// NE PAS MODIFIER
static unsigned int4_to_color (int4 i)
{
  return (unsigned) convert_uchar4 (i);
}


__kernel void life (__global unsigned *in, __global unsigned *out, __global unsigned char *change)
{
	int x = get_global_id(0);
	int y = get_global_id(1);

	if (y > 0 && y < DIM-1 && x > 0 && x < DIM-1) {
		int count = 0;

		count += (in[(y)*DIM+x-1] == 0) ? 0 : 1;
		count += (in[(y-1)*DIM+x] == 0) ? 0 : 1;
		count += (in[(y+1)*DIM+x] == 0) ? 0 : 1;
		count += (in[(y)*DIM+x+1] == 0) ? 0 : 1;
		count += (in[(y-1)*DIM+x-1] == 0) ? 0 : 1;
		count += (in[(y+1)*DIM+x-1] == 0) ? 0 : 1;
		count += (in[(y+1)*DIM+x+1] == 0) ? 0 : 1;
		count += (in[(y-1)*DIM+x+1] == 0) ? 0 : 1;

		if (in[y*DIM+x] == 0)
			if (count == 3)
				out[y*DIM+x] = RED;
			else
				out[y*DIM+x] = 0;
		else
			if (count == 2 || count == 3)
				out[y*DIM+x] = YELLOW;
			else
				out[y*DIM+x] = 0;

		if ((in[y*DIM+x] & ALPHA_MASK) != (out[y*DIM+x] & ALPHA_MASK))
			*change = 1;
	}
}




__kernel void life_opti (__global unsigned *in,
						__global unsigned *out,
						__global unsigned char *change,
						__global unsigned char *curr_tile,
						__global unsigned char *next_tile)
{
	int x = get_global_id(0);
	int y = get_global_id(1);

	unsigned nb_tiles = ((DIM + TILEX-1) / TILEX);
	unsigned xTile = x / TILEX;
	unsigned yTile = y / TILEY;

	if (curr_tile[xTile + nb_tiles  * yTile]) {
		if (y > 0 && y < DIM-1 && x > 0 && x < DIM-1) {
			int count = 0;

			/*count += ((in[(y)*DIM+x-1] & RED_MASK)== 0) ? 0 : 1;
			count += ((in[(y-1)*DIM+x] & RED_MASK)== 0) ? 0 : 1;
			count += ((in[(y+1)*DIM+x] & RED_MASK)== 0) ? 0 : 1;
			count += ((in[(y)*DIM+x+1] & RED_MASK)== 0) ? 0 : 1;
			count += ((in[(y-1)*DIM+x-1] & RED_MASK)== 0) ? 0 : 1;
			count += ((in[(y+1)*DIM+x-1] & RED_MASK)== 0) ? 0 : 1;
			count += ((in[(y+1)*DIM+x+1] & RED_MASK)== 0) ? 0 : 1;
			count += ((in[(y-1)*DIM+x+1] & RED_MASK)== 0) ? 0 : 1;*/
			count += (in[(y)*DIM+x-1] == 0) ? 0 : 1;
			count += (in[(y-1)*DIM+x] == 0) ? 0 : 1;
			count += (in[(y+1)*DIM+x] == 0) ? 0 : 1;
			count += (in[(y)*DIM+x+1] == 0) ? 0 : 1;
			count += (in[(y-1)*DIM+x-1] == 0) ? 0 : 1;
			count += (in[(y+1)*DIM+x-1] == 0) ? 0 : 1;
			count += (in[(y+1)*DIM+x+1] == 0) ? 0 : 1;
			count += (in[(y-1)*DIM+x+1] == 0) ? 0 : 1;

			if ((in[y*DIM+x] /*& RED_MASK*/) == 0)
				if (count == 3)
					out[y*DIM+x] = RED;
				else
					out[y*DIM+x] = 0;
			else
				if (count == 2 || count == 3)
					out[y*DIM+x] = YELLOW;
				else
					out[y*DIM+x] = 0;


			if ((RED_MASK & in[y*DIM+x]) != (RED_MASK & out[y*DIM+x])){
				*change = 1;
				next_tile[xTile + yTile * nb_tiles] = true;

				if (xTile < nb_tiles -1) {	//droite
					next_tile[xTile+1 + yTile * nb_tiles] = true;
					if (yTile < nb_tiles -1) {	//bas
						next_tile[(xTile+1) + (yTile+1) * nb_tiles] = true;
					}
					if (yTile > 0) {	//haut
						next_tile[(xTile+1) + (yTile-1) * nb_tiles] = true;
					}
				}
				if (xTile > 0) {	//gauche
					next_tile[xTile-1 + yTile * nb_tiles] = true;
					if (yTile < nb_tiles -1) {	//bas
						next_tile[(xTile-1) + (yTile+1) * nb_tiles] = true;
					}
					if (yTile > 0) {	//haut
						next_tile[(xTile-1) + (yTile-1) * nb_tiles] = true;
					}
				}

				if (yTile < nb_tiles -1) {	//bas
					next_tile[xTile + (yTile+1) * nb_tiles] = true;
				}
				if (yTile > 0) {	//haut
					next_tile[xTile + (yTile-1) * nb_tiles] = true;
				}

				/*
				unsigned end_tile_x = (xTile+1) * TILEX < DIM-1 ? (xTile+1) * TILEX : DIM-1;
				unsigned end_tile_y = (yTile+1) * TILEY < DIM-1 ? (yTile+1) * TILEY : DIM-1;

				if (x == end_tile_x && xTile != nb_tiles -1) { 	//droite
					next_tile[xTile+1 + yTile * nb_tiles] = true;
					if (y == end_tile_y && yTile != nb_tiles -1) { 	//bas
						next_tile[xTile+1 + (yTile+1) * nb_tiles] = true;
					}
					if (y == yTile * TILEY +1 && yTile != 0) {	//haut
						next_tile[xTile+1 + (yTile-1) * nb_tiles] = true;
					}
				}
				if (x == xTile * TILEX +1 && xTile != 0) {	//gauche
					next_tile[xTile-1 + yTile * nb_tiles] = true;
					if (y == end_tile_y && yTile != nb_tiles -1) { 	//bas
						next_tile[xTile-1 + (yTile+1) * nb_tiles] = true;
					}
					if (y == yTile * TILEY +1 && yTile != 0) {	//haut
						next_tile[xTile-1 + (yTile-1) * nb_tiles] = true;
					}
				}
				if (y == end_tile_y && yTile != nb_tiles -1) { 	//bas
					next_tile[xTile + (yTile+1) * nb_tiles] = true;
				}
				if (y == yTile * TILEY +1 && yTile != 0) {	//haut
					next_tile[xTile + (yTile-1) * nb_tiles] = true;
				}*/

			}
		}
		//out[y*DIM+x] |= BLUE;
	}
}


// NE PAS MODIFIER
static float4 color_scatter (unsigned c)
{
  uchar4 ci;

  ci.s0123 = (*((uchar4 *) &c)).s3210;
  return convert_float4 (ci) / (float4) 255;
}

// NE PAS MODIFIER: ce noyau est appelé lorsqu'une mise à jour de la
// texture de l'image affichée est requise
__kernel void update_texture (__global unsigned *cur, __write_only image2d_t tex)
{
  int y = get_global_id (1);
  int x = get_global_id (0);
  int2 pos = (int2)(x, y);
  unsigned c;

  c = cur [y * DIM + x];

  write_imagef (tex, pos, color_scatter (c));
}
