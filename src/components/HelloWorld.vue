<script setup>
defineProps({
  name: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="greetings">
    <h3>
      Deadpool says: Hello <span class="green"> {{ name }} </span>!!!
    </h3>
  </div>
</template>

<style scoped>
h3 {
  font-size: 1.2rem;
}

.greetings h3 {
  text-align: center;
}

@media (min-width: 1024px) {
  .greetings h3 {
    text-align: left;
  }
}
</style>
