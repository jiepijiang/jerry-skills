import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

import './styles/root.css'
import './styles/base.css'
import './styles/hub.css'

createApp(App).use(router).mount('#app')
