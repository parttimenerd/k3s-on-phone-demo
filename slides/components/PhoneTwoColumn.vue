<template>
  <div class="grid grid-cols-3 gap-4 h-full">
    <div class="col-span-2">
      <slot></slot>
    </div>
    
    <div style="margin: -20px 10px 10px 0; position: relative; height: 128%; width: 100%;">
      <!-- First image shown immediately -->
      <div v-if="images.length > 0" style="position: absolute; top: 0; left: 0; right: 0; bottom: 0; border: 1px solid #ccc; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); overflow: hidden; display: flex; align-items: center; justify-content: center;">
        <img :src="images[0]" alt="Phone screenshot" style="width: 400px; height: 102.5%; object-fit: contain; object-position: 0 -30px;" />
      </div>
      
      <!-- Subsequent images with v-click -->
      <v-click v-for="(image, index) in images.slice(1)" :key="'img-' + index">
        <div style="position: absolute; top: 0; left: 0; right: 0; bottom: 0; border: 1px solid #ccc; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); overflow: hidden; display: flex; align-items: center; justify-content: center;">
          <img :src="image" alt="Phone screenshot" style="width: auto; height: 102.5%; object-fit: contain; object-position: 0 -30px;" />
        </div>
      </v-click>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps({
  img: {
    type: [String, Array],
    required: true,
  },
})

const images = computed(() => (Array.isArray(props.img) ? props.img : [props.img]))
</script>
