import { Stack } from 'expo-router';
import React, { createContext, useContext, useState } from 'react';

const UserContext = createContext<any>(null);
export const useUser = () => useContext(UserContext);

export default function RootLayout() {
  const [userData, setUserData] = useState({
    nombre: '',
    monto: '0',
    ocupacion: '',
    inicializado: false 
  });

  const [gastos, setGastos] = useState([]);

  return (
    <UserContext.Provider value={{ userData, setUserData, gastos, setGastos }}>
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: '#fff' } }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="perfil" />
        <Stack.Screen name="registro" options={{ presentation: 'modal' }} />
      </Stack>
    </UserContext.Provider>
  );
}