import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { PrismaClient } from "@prisma/client";
import { authenticateToken } from '../auth/auth.middleware';

const prisma = new PrismaClient();
export const userRouter = Router();

// Créer un utilisateur protégé
userRouter.post('/', authenticateToken, async (req: Request, res: Response) => {
  const { username, email, password } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { username, email, password: hashedPassword },
      select: { id: true, username: true, email: true },
    });
    res.status(201).json({ message: 'Utilisateur créé', user });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Récupérer les infos de l'utilisateur connecté
userRouter.get('/me', authenticateToken, async (req: Request, res: Response) => {
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    select: { id: true, username: true, email: true },
  });
  res.status(200).json({ user });
});
