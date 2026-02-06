import { describe, it, expect, vi, beforeEach } from 'vitest'
import request from 'supertest'
import { app } from '../src/index'
import { prismaMock } from './vitest.setup'
import { authenticateToken } from '../src/auth/auth.middleware'
import { PokemonType } from '../src/generated/prisma/enums'

vi.mock('../src/auth/auth.middleware')

vi.mocked(authenticateToken).mockImplementation((req, _res, next) => {
  req.user = { userId: 1, email: 'test@example.com' }
  next()
})

const cardIds = Array.from({ length: 10 }, (_, i) => i + 1)
const mockCards = cardIds.map(id => ({
  id,
  name: `Card ${id}`,
  hp: 50,
  attack: 50,
  type: PokemonType.Normal,
  pokedexNumber: id,
  imgUrl: `https://example.com/${id}.png`,
  createdAt: new Date(),
  updatedAt: new Date()
}))

const baseDeck = {
  id: 1,
  name: 'My Deck',
  userId: 1,
  createdAt: new Date(),
  updatedAt: new Date()
}

beforeEach(() => {
  vi.clearAllMocks()
})

describe('POST /api/decks', () => {
  it('creates a deck', async () => {
    prismaMock.card.findMany.mockResolvedValue(mockCards)
    prismaMock.deck.create.mockResolvedValue({
      ...baseDeck,
      Cards: mockCards.map((card, i) => ({
        id: i + 1,
        deckId: 1,
        cardId: card.id,
        card
      }))
    })

    const res = await request(app)
      .post('/api/decks')
      .send({ name: 'My Deck', cards: cardIds })

    expect(res.status).toBe(201)
    expect(res.body.cards).toHaveLength(10)
  })

  it.each([
    [{ cards: cardIds }, 'Le nom du deck est requis'],
    [{ name: 'My Deck', cards: 'x' }, 'Les cartes doivent être un tableau'],
    [{ name: 'My Deck', cards: [1, 2] }, 'Un deck doit contenir exactement 10 cartes']
  ])('returns 400 (%s)', async (body, error) => {
    const res = await request(app).post('/api/decks').send(body)
    expect(res.status).toBe(400)
    expect(res.body.error).toBe(error)
  })

  it('returns 400 if cards invalid', async () => {
    prismaMock.card.findMany.mockResolvedValue([])

    const res = await request(app)
      .post('/api/decks')
      .send({ name: 'My Deck', cards: cardIds })

    expect(res.status).toBe(400)
  })

  it('returns 500 on error', async () => {
    prismaMock.card.findMany.mockRejectedValue(new Error())

    const res = await request(app)
      .post('/api/decks')
      .send({ name: 'My Deck', cards: cardIds })

    expect(res.status).toBe(500)
  })
})

describe('GET /api/decks', () => {
  it('returns user decks', async () => {
    prismaMock.deck.findMany.mockResolvedValue([{ ...baseDeck, cards: [] }])

    const res = await request(app).get('/api/decks/mine')

    expect(res.status).toBe(200)
    expect(res.body).toHaveLength(1)
  })

  it('returns 500 on error', async () => {
    prismaMock.deck.findMany.mockRejectedValue(new Error())
    expect((await request(app).get('/api/decks/mine')).status).toBe(500)
  })
})

describe('GET /api/decks/:id', () => {
  it('returns a deck', async () => {
    prismaMock.deck.findUnique.mockResolvedValue({ ...baseDeck, cards: [] })
    expect((await request(app).get('/api/decks/1')).status).toBe(200)
  })

  it.each([
    [null, 404, 'Deck non trouvé'],
    [{ ...baseDeck, userId: 2 }, 403, 'Accès non autorisé à ce deck']
  ])('returns error', async (deck, status, msg) => {
    prismaMock.deck.findUnique.mockResolvedValue(deck as any)
    const res = await request(app).get('/api/decks/1')
    expect(res.status).toBe(status)
    expect(res.body.error).toBe(msg)
  })
})

describe('PATCH /api/decks/:id', () => {
  it('updates name', async () => {
    prismaMock.deck.findUnique.mockResolvedValue(baseDeck)
    prismaMock.deck.update.mockResolvedValue({ ...baseDeck, name: 'New' })

    const res = await request(app)
      .patch('/api/decks/1')
      .send({ name: 'New' })

    expect(res.body.name).toBe('New')
  })

  it('updates cards', async () => {
    prismaMock.deck.findUnique.mockResolvedValue(baseDeck)
    prismaMock.card.findMany.mockResolvedValue(mockCards)
    prismaMock.deckCard.deleteMany.mockResolvedValue({ count: 10 })
    prismaMock.deckCard.createMany.mockResolvedValue({ count: 10 })
    prismaMock.deck.update.mockResolvedValue({ ...baseDeck, cards: [] })

    expect(
      (await request(app).patch('/api/decks/1').send({ cards: cardIds })).status
    ).toBe(200)
  })
})

describe('DELETE /api/decks/:id', () => {
  it('deletes a deck', async () => {
    prismaMock.deck.findUnique.mockResolvedValue(baseDeck)
    prismaMock.deckCard.deleteMany.mockResolvedValue({ count: 10 })
    prismaMock.deck.delete.mockResolvedValue(baseDeck)

    const res = await request(app).delete('/api/decks/1')
    expect(res.status).toBe(200)
  })
})