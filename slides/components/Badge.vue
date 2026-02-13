<template>
  <span :class="['inline-flex items-center px-2 py-0.5 rounded-md text-xs font-semibold', variantClass]">
    <slot />
  </span>
</template>

<script setup>
const props = defineProps({
  variant: { type: String, default: 'orange' },
});

const variantClass = {
  orange: 'bg-orange-500/15 text-orange-400',
  blue: 'bg-blue-500/15 text-blue-400',
  red: 'bg-red-500/15 text-red-400',
  green: 'bg-emerald-500/15 text-emerald-400',
  gray: 'bg-gray-500/15 text-gray-300',
}[props.variant] || 'bg-orange-500/15 text-orange-400';
</script>
