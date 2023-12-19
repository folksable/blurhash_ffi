#include "blurhash_ffi.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static inline int linearTosRGB(float value) {
	float v = fmaxf(0, fminf(1, value));
	if(v <= 0.0031308) return v * 12.92 * 255 + 0.5;
	else return (1.055 * powf(v, 1 / 2.4) - 0.055) * 255 + 0.5;
}

static inline float sRGBToLinear(int value) {
	float v = (float)value / 255;
	if(v <= 0.04045) return v / 12.92;
	else return powf((v + 0.055) / 1.055, 2.4);
}

static inline float signPow(float value, float exp) {
	return copysignf(powf(fabsf(value), exp), value);
}


static float *multiplyBasisFunction(int xComponent, int yComponent, int width, int height, uint8_t *rgb, int64_t bytesPerRow);
static char *encode_int(int value, int length, char *destination);

static int encodeDC(float r, float g, float b);
static int encodeAC(float r, float g, float b, float maximumValue);

const char *blurHashForPixels(int xComponents, int yComponents, int width, int height, uint8_t *rgb, int64_t bytesPerRow) {
	static char buffer[2 + 4 + (9 * 9 - 1) * 2 + 1];

	if(xComponents < 1 || xComponents > 9) return NULL;
	if(yComponents < 1 || yComponents > 9) return NULL;

	float *factors = calloc(yComponents * xComponents * 3, sizeof(float));
	if(factors == NULL) {
		buffer[0] = '\0';
		return buffer;
	}

	for(int y = 0; y < yComponents; y++) {
		for(int x = 0; x < xComponents; x++) {
			float *factor = multiplyBasisFunction(x, y, width, height, rgb, bytesPerRow);
			factors[(y * xComponents + x) * 3 + 0] = factor[0];
			factors[(y * xComponents + x) * 3 + 1] = factor[1];
			factors[(y * xComponents + x) * 3 + 2] = factor[2];
		}
	}

	float *dc = &factors[0];
	float *ac = dc + 3;
	int acCount = xComponents * yComponents - 1;
	char *ptr = buffer;

	int sizeFlag = (xComponents - 1) + (yComponents - 1) * 9;
	ptr = encode_int(sizeFlag, 1, ptr);

	float maximumValue;
	if(acCount > 0) {
		float actualMaximumValue = 0;
		for(int i = 0; i < acCount * 3; i++) {
			actualMaximumValue = fmaxf(fabsf(ac[i]), actualMaximumValue);
		}

		int quantisedMaximumValue = fmaxf(0, fminf(82, floorf(actualMaximumValue * 166 - 0.5)));
		maximumValue = ((float)quantisedMaximumValue + 1) / 166;
		ptr = encode_int(quantisedMaximumValue, 1, ptr);
	} else {
		maximumValue = 1;
		ptr = encode_int(0, 1, ptr);
	}

	ptr = encode_int(encodeDC(dc[0], dc[1], dc[2]), 4, ptr);

	for(int i = 0; i < acCount; i++) {
		ptr = encode_int(encodeAC(ac[i * 3 + 0], ac[i * 3 + 1], ac[i * 3 + 2], maximumValue), 2, ptr);
	}

	*ptr = 0;

	free(factors);

	return buffer;
}

static float *multiplyBasisFunction(int xComponent, int yComponent, int width, int height, uint8_t *rgb, int64_t bytesPerRow) {
	float r = 0, g = 0, b = 0;
	float normalisation = (xComponent == 0 && yComponent == 0) ? 1 : 2;

	for(int y = 0; y < height; y++) {
		for(int x = 0; x < width; x++) {
			float basis = cosf(M_PI * xComponent * x / width) * cosf(M_PI * yComponent * y / height);
			r += basis * sRGBToLinear(rgb[3 * x + 0 + y * bytesPerRow]);
			g += basis * sRGBToLinear(rgb[3 * x + 1 + y * bytesPerRow]);
			b += basis * sRGBToLinear(rgb[3 * x + 2 + y * bytesPerRow]);
		}
	}

	float scale = normalisation / (width * height);

	static float result[3];
	result[0] = r * scale;
	result[1] = g * scale;
	result[2] = b * scale;

	return result;
}



static int encodeDC(float r, float g, float b) {
	int roundedR = linearTosRGB(r);
	int roundedG = linearTosRGB(g);
	int roundedB = linearTosRGB(b);
	return (roundedR << 16) + (roundedG << 8) + roundedB;
}

static int encodeAC(float r, float g, float b, float maximumValue) {
	int quantR = fmaxf(0, fminf(18, floorf(signPow(r / maximumValue, 0.5) * 9 + 9.5)));
	int quantG = fmaxf(0, fminf(18, floorf(signPow(g / maximumValue, 0.5) * 9 + 9.5)));
	int quantB = fmaxf(0, fminf(18, floorf(signPow(b / maximumValue, 0.5) * 9 + 9.5)));

	return quantR * 19 * 19 + quantG * 19 + quantB;
}

static char characters[83]="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~";

static char *encode_int(int value, int length, char *destination) {
	int divisor = 1;
	for(int i = 0; i < length - 1; i++) divisor *= 83;

	for(int i = 0; i < length; i++) {
		int digit = (value / divisor) % 83;
		divisor /= 83;
		*destination++ = characters[digit];
	}
	return destination;
}

static inline uint8_t clampToUByte(int * src) {
	if( *src >= 0 && *src <= 255 )
		return *src;
	return (*src < 0) ? 0 : 255;
}

static inline uint8_t *  createByteArray(int size) {
	return (uint8_t *)malloc(size * sizeof(uint8_t));
}

int decodeToInt(const char * string, int start, int end) {
	int value = 0, iter1 = 0, iter2 = 0;
	for( iter1 = start; iter1 < end; iter1 ++) {
		int index = -1;
		for(iter2 = 0; iter2 < 83; iter2 ++) {
			if (characters[iter2] == string[iter1]) {
				index = iter2;
				break;
			}
		}
		if (index == -1) return -1;
		value = value * 83 + index;
	}
	return value;
}

bool isValidBlurhash(const char * blurhash) {

	const size_t hashLength = strlen(blurhash);

	if ( !blurhash || hashLength < 6) return 0;

	int sizeFlag = decodeToInt(blurhash, 0, 1);	//Get size from first character
	int numY = (int)floorf(sizeFlag / 9) + 1;
	int numX = (sizeFlag % 9) + 1;

	if (hashLength != 4 + 2 * numX * numY) return 0;
	return 1;
}

void decodeDC(int value, float * r, float * g, float * b) {
	*r = sRGBToLinear(value >> 16); 	// R-component
	*g = sRGBToLinear((value >> 8) & 255); // G-Component
	*b = sRGBToLinear(value & 255);	// B-Component
}

void decodeAC(int value, float maximumValue, float * r, float * g, float * b) {
	int quantR = (int)floorf(value / (19 * 19));
	int quantG = (int)floorf(value / 19) % 19;
	int quantB = (int)value % 19;

	*r = signPow(((float)quantR - 9) / 9, 2.0) * maximumValue;
	*g = signPow(((float)quantG - 9) / 9, 2.0) * maximumValue;
	*b = signPow(((float)quantB - 9) / 9, 2.0) * maximumValue;
}

int decodeToArray(const char * blurhash, int width, int height, int punch, int nChannels, uint8_t * pixelArray) {
	if (! isValidBlurhash(blurhash)) return -1;
	if (punch < 1) punch = 1;

	int sizeFlag = decodeToInt(blurhash, 0, 1);
	int numY = (int)floorf(sizeFlag / 9) + 1;
	int numX = (sizeFlag % 9) + 1;
	int iter = 0;

	float r = 0, g = 0, b = 0;
	int quantizedMaxValue = decodeToInt(blurhash, 1, 2);
	if (quantizedMaxValue == -1) return -1;

	float maxValue = ((float)(quantizedMaxValue + 1)) / 166;

	int colors_size = numX * numY;
	float *colors = malloc(colors_size * 3 * sizeof(float));
	if(colors == NULL) return -1;

	for(iter = 0; iter < colors_size; iter ++) {
		if (iter == 0) {
			int value = decodeToInt(blurhash, 2, 6);
			if (value == -1) {
				free(colors);
				return -1;
			}
			decodeDC(value, &r, &g, &b);
			colors[iter * 3 + 0] = r;
			colors[iter * 3 + 1] = g;
			colors[iter * 3 + 2] = b;

		} else {
			int value = decodeToInt(blurhash, 4 + iter * 2, 6 + iter * 2);
			if (value == -1) {
				free(colors);
				return -1;
			}
			decodeAC(value, maxValue * punch, &r, &g, &b);
			colors[iter * 3 + 0] = r;
			colors[iter * 3 + 1] = g;
			colors[iter * 3 + 2] = b;
		}
	}
	int bytesPerRow = width * nChannels;
	int x = 0, y = 0, i = 0, j = 0;
	int intR = 0, intG = 0, intB = 0;

	for(y = 0; y < height; y ++) {
		for(x = 0; x < width; x ++) {

			float r = 0, g = 0, b = 0;

			for(j = 0; j < numY; j ++) {
				for(i = 0; i < numX; i ++) {
					float basics = cos((M_PI * x * i) / width) * cos((M_PI * y * j) / height);
					int idx = i + j * numX;
					r += colors[idx * 3 + 0] * basics;
					g += colors[idx * 3 + 1] * basics;
					b += colors[idx * 3 + 2] * basics;
				}
			}

			intR = linearTosRGB(r);
			intG = linearTosRGB(g);
			intB = linearTosRGB(b);

			pixelArray[nChannels * x + 0 + y * bytesPerRow] = clampToUByte(&intR);
			pixelArray[nChannels * x + 1 + y * bytesPerRow] = clampToUByte(&intG);
			pixelArray[nChannels * x + 2 + y * bytesPerRow] = clampToUByte(&intB);

			if (nChannels == 4)
				pixelArray[nChannels * x + 3 + y * bytesPerRow] = 255;   // If nChannels=4, treat each pixel as RGBA instead of RGB

		}
	}

	free(colors);

	return 0;
}

uint8_t * decode(const char * blurhash, int width, int height, int punch, int nChannels) {
	int bytesPerRow = width * nChannels;
	uint8_t * pixelArray = createByteArray(bytesPerRow * height);

	if (decodeToArray(blurhash, width, height, punch, nChannels, pixelArray) == -1)
		return NULL;
	return pixelArray;
}

void freePixelArray(uint8_t * pixelArray) {
	if (pixelArray) {
		free(pixelArray);
	}
}