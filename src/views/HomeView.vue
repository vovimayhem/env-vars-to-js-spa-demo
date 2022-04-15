<script setup>
import HelloWorld from "../components/HelloWorld.vue";
const { VITE_APP_SALUTE_NAME } = window;
</script>

<template>
  <main>
    <HelloWorld :name="VITE_APP_SALUTE_NAME" />
  </main>
</template>
