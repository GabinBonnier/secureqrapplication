import {Router, Request, Response} from 'express'
import {prisma} from '../../database'
import {authenticateToken} from '../../auth/auth.middleware'

const router = Router()

// Appliquer le middleware d'authentification à toutes les routes
router.use(authenticateToken)

// POST /api/decks - Créer un nouveau deck
router.post('/', async (req: Request, res: Response) => {
    const {name, cards} = req.body

    try {
        // Validation des données
        if (!name) {
            return res.status(400).json({error: 'Le nom du deck est requis'})
        }

        if (!cards || !Array.isArray(cards)) {
            return res.status(400).json({error: 'Les cartes doivent être un tableau'})
        }

        if (cards.length !== 10) {
            return res.status(400).json({error: 'Un deck doit contenir exactement 10 cartes'})
        }

        // Vérifier que toutes les cartes existent
        const existingCards = await prisma.card.findMany({
            where: {
                id: {in: cards}
            }
        })

        if (existingCards.length !== 10) {
            return res.status(400).json({error: 'Une ou plusieurs cartes sont invalides'})
        }

        // Créer le deck
        const deck = await prisma.deck.create({
            data: {
                name,
                userId: req.user!.userId,
                cards: {
                    create: cards.map(cardId => ({
                        cardId
                    }))
                }
            },
            include: {
                cards: {
                    include: {
                        card: true
                    }
                }
            }
        })

        return res.status(201).json(deck)
    } catch (error) {
        console.error('Erreur lors de la création du deck:', error)
        return res.status(500).json({error: 'Erreur serveur'})
    }
})

// GET /api/decks/mine - Lister tous les decks de l'utilisateur
router.get('/mine', async (req: Request, res: Response) => {
    try {
        const decks = await prisma.deck.findMany({
            where: {
                userId: req.user!.userId
            },
            include: {
                cards: {
                    include: {
                        card: true
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        })

        return res.status(200).json(decks)
    } catch (error) {
        console.error('Erreur lors de la récupération des decks:', error)
        return res.status(500).json({error: 'Erreur serveur'})
    }
})

// GET /api/decks/:id - Consulter un deck spécifique
router.get('/:id', async (req: Request, res: Response) => {
    const {id} = req.params

    try {
        const deck = await prisma.deck.findUnique({
            where: {
                id: parseInt(id)
            },
            include: {
                cards: {
                    include: {
                        card: true
                    }
                }
            }
        })

        if (!deck) {
            return res.status(404).json({error: 'Deck non trouvé'})
        }

        // Vérifier que le deck appartient à l'utilisateur
        if (deck.userId !== req.user!.userId) {
            return res.status(403).json({error: 'Accès non autorisé à ce deck'})
        }

        return res.status(200).json(deck)
    } catch (error) {
        console.error('Erreur lors de la récupération du deck:', error)
        return res.status(500).json({error: 'Erreur serveur'})
    }
})

// PATCH /api/decks/:id - Modifier un deck
router.patch('/:id', async (req: Request, res: Response) => {
    const {id} = req.params
    const {name, cards} = req.body

    try {
        // Vérifier que le deck existe
        const existingDeck = await prisma.deck.findUnique({
            where: {
                id: parseInt(id)
            }
        })

        if (!existingDeck) {
            return res.status(404).json({error: 'Deck non trouvé'})
        }

        // Vérifier que le deck appartient à l'utilisateur
        if (existingDeck.userId !== req.user!.userId) {
            return res.status(403).json({error: 'Accès non autorisé à ce deck'})
        }

        // Si des cartes sont fournies, les valider
        if (cards !== undefined) {
            if (!Array.isArray(cards)) {
                return res.status(400).json({error: 'Les cartes doivent être un tableau'})
            }

            if (cards.length !== 10) {
                return res.status(400).json({error: 'Un deck doit contenir exactement 10 cartes'})
            }

            // Vérifier que toutes les cartes existent
            const existingCards = await prisma.card.findMany({
                where: {
                    id: {in: cards}
                }
            })

            if (existingCards.length !== 10) {
                return res.status(400).json({error: 'Une ou plusieurs cartes sont invalides'})
            }

            // Supprimer les anciennes associations
            await prisma.deckCard.deleteMany({
                where: {
                    deckId: parseInt(id)
                }
            })

            // Créer les nouvelles associations
            await prisma.deckCard.createMany({
                data: cards.map(cardId => ({
                    deckId: parseInt(id),
                    cardId
                }))
            })
        }

        // Mettre à jour le deck
        const updatedDeck = await prisma.deck.update({
            where: {
                id: parseInt(id)
            },
            data: {
                ...(name && {name})
            },
            include: {
                cards: {
                    include: {
                        card: true
                    }
                }
            }
        })

        return res.status(200).json(updatedDeck)
    } catch (error) {
        console.error('Erreur lors de la modification du deck:', error)
        return res.status(500).json({error: 'Erreur serveur'})
    }
})

// DELETE /api/decks/:id - Supprimer un deck
router.delete('/:id', async (req: Request, res: Response) => {
    const {id} = req.params

    try {
        // Vérifier que le deck existe
        const existingDeck = await prisma.deck.findUnique({
            where: {
                id: parseInt(id)
            }
        })

        if (!existingDeck) {
            return res.status(404).json({error: 'Deck non trouvé'})
        }

        // Vérifier que le deck appartient à l'utilisateur
        if (existingDeck.userId !== req.user!.userId) {
            return res.status(403).json({error: 'Accès non autorisé à ce deck'})
        }

        // Supprimer les DeckCards associés
        await prisma.deckCard.deleteMany({
            where: {
                deckId: parseInt(id)
            }
        })

        // Supprimer le deck
        await prisma.deck.delete({
            where: {
                id: parseInt(id)
            }
        })

        return res.status(200).json({message: 'Deck supprimé avec succès'})
    } catch (error) {
        console.error('Erreur lors de la suppression du deck:', error)
        return res.status(500).json({error: 'Erreur serveur'})
    }
})

export default router
