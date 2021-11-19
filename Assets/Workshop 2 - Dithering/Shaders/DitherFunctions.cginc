#ifndef __DITHER_FUNCTIONS__
#define __DITHER_FUNCTIONS__
#include "UnityCG.cginc"

// https://en.wikipedia.org/wiki/Ordered_dithering
static const float bayerMatrix[16] =
{
    1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
    13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
    4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
    16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
};

float isDithered(float2 pos, float alpha) {
    pos *= _ScreenParams.xy;
    uint index = (uint(pos.x) % 4) * 4 + uint(pos.y) % 4;
    return alpha - bayerMatrix[index];
}

void ditherClip(float2 pos, float alpha) {
    clip(isDithered(pos, alpha));
}

#endif