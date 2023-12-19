#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#elif __APPLE__
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#else
#define FFI_PLUGIN_EXPORT
#endif

/*
	encode : Returns the blurhash string for the given image
	This function returns a string containing the BlurHash. This memory is managed by the function, and you should not free it.
	It will be overwritten on the next call into the function, so be careful!
	Parameters : 
		`xComponents` - The number of components in the X direction. Must be between 1 and 9. 3 to 5 is usually a good range for this.
		`yComponents` - The number of components in the Y direction. Must be between 1 and 9. 3 to 5 is usually a good range for this.
		`width` - The width in pixels of the supplied image.
		`height` - The height in pixels of the supplied image.
		`rgb` - A pointer to the pixel data. This is supplied in RGB order, with 3 bytes per pixels.
		`bytesPerRow` - The number of bytes per row of the RGB pixel data.
*/

FFI_PLUGIN_EXPORT
const char *blurHashForPixels(int xComponents, int yComponents, int width, int height, uint8_t *rgb, int64_t bytesPerRow);

/*
	decode : Returns the pixel array of the result image given the blurhash string,
	Parameters : 
		blurhash : A string representing the blurhash to be decoded.
		width : Width of the resulting image
		height : Height of the resulting image
		punch : The factor to improve the contrast, default = 1
		nChannels : Number of channels in the resulting image array, 3 = RGB, 4 = RGBA
	Returns : A pointer to memory region where pixels are stored in (H, W, C) format
*/
FFI_PLUGIN_EXPORT 
uint8_t * decode(const char * blurhash, int width, int height, int punch, int nChannels);

/*
	decodeToArray : Decodes the blurhash and copies the pixels to pixelArray,
					This method is suggested if you use an external memory allocator for pixelArray.
					pixelArray should be of size : width * height * nChannels
	Parameters :
		blurhash : A string representing the blurhash to be decoded.
		width : Width of the resulting image
		height : Height of the resulting image
		punch : The factor to improve the contrast, default = 1
		nChannels : Number of channels in the resulting image array, 3 = RGB, 4 = RGBA
		pixelArray : Pointer to memory region where pixels needs to be copied.
	Returns : int, -1 if error 0 if successful
*/
FFI_PLUGIN_EXPORT 
int decodeToArray(const char * blurhash, int width, int height, int punch, int nChannels, uint8_t * pixelArray);

/*
	isValidBlurhash : Checks if the Blurhash is valid or not.
	Parameters :
		blurhash : A string representing the blurhash
	Returns : bool (true if it is a valid blurhash, else false)
*/
FFI_PLUGIN_EXPORT
bool isValidBlurhash(const char * blurhash); 

/*
	freePixelArray : Frees the pixel array
	Parameters :
		pixelArray : Pixel array pointer which will be freed.
	Returns : void (None)
*/
FFI_PLUGIN_EXPORT
void freePixelArray(uint8_t * pixelArray);
