<template>
  <div class="grid grid-cols-4 gap-4 h-full">
    <div class="col-span-2">
      <slot></slot>
    </div>
    
    <div style="margin: -10px 20px 20px 0; position: relative; height: 100%; width: 220%;">
      <!-- First image shown immediately with zoom -->
      <div v-if="clickToReveal == true">
        <v-click>
        <div v-if="images.length > 0" style="position: absolute; top: 0; left: 0; right: 0; bottom: 0; border: 1px solid #ccc; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); overflow: hidden; display: flex; align-items: center; justify-content: center;">
            <img :src="images[0]" alt="Phone screenshot" :style="{ width: width + 'px', height: height + 'px', objectFit: 'contain', objectPosition: objectPositionStr }" />
        </div>
        </v-click>
      </div>

    <div v-if="!clickToReveal">
        <div v-if="images.length > 0" style="position: absolute; top: 0; left: 0; right: 0; bottom: 0; border: 1px solid #ccc; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); overflow: hidden; display: flex; align-items: center; justify-content: center;">
            <img :src="images[0]" alt="Phone screenshot" :style="{ width: width + 'px', height: height + 'px', objectFit: 'contain', objectPosition: objectPositionStr }" />
        </div>
    </div>
        
      <!-- Subsequent images with v-click and zoom -->
      <v-click v-for="(image, index) in images.slice(1)" :key="'img-' + index">
        <div style="position: absolute; top: 0; left: 0; right: 0; bottom: 0; border: 1px solid #ccc; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); overflow: hidden; display: flex; align-items: center; justify-content: center;">
          <img :src="image" alt="Phone screenshot" :style="{ width: width + 'px', height: height + 'px', objectFit: 'contain', objectPosition: objectPositionStr }" />
        </div>
      </v-click>
    </div>
  </div>
</template>

<script setup lang="ts">
import { version } from 'react'
import { computed } from 'vue'

const props = defineProps({
  img: {
    type: [String, Array],
    required: true,
  },
  offsetY: {
    type: Number,
    default: -30, // vertical offset in pixels (negative = up, positive = down)
  },
  clickToReveal: {
    type: Boolean,
    default: false,
  }
})

const images = computed(() => (Array.isArray(props.img) ? props.img : [props.img]))

const width = computed(() => 400 * props.zoom)
const height = computed(() => 102.5 * props.zoom)
const objectPositionStr = computed(() => `0 ${props.offsetY+195}px`)
</script>
